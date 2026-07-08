_: {
  flake.factory.github-runners =
    { count }:
    {
      config,
      lib,
      ...
    }:
    let
      # Relative form for systemd CacheDirectory= (base /var/cache).
      cacheSubdir = num: "github-runners/nixos-runner-${toString num}";
      workDirFor = num: "/var/cache/${cacheSubdir num}";
    in
    {
      # The runners share a static system user (see `user`/`group` below). A
      # static user is required because a disk-backed workDir under DynamicUser
      # lands in /var/{lib,cache}/private with a symlink, and actions/checkout v6
      # writes git credentials via `includeIf.gitdir:<workDir>`; git resolves that
      # symlink, the condition never matches, and checkout fails with "could not
      # read Username". See https://github.com/actions/checkout/issues/2393.
      users.users.github-runner = {
        isSystemUser = true;
        group = "github-runner";
      };
      users.groups.github-runner = { };
      sops.secrets."github-runners/pat".owner = "github-runner";
      sops.secrets."github-runners/age-key".owner = "github-runner";
      sops.secrets."github-runners/aws-access-key-id".owner = "github-runner";
      sops.secrets."github-runners/aws-secret-access-key".owner = "github-runner";
      sops.templates."state-backend-secrets" = {
        owner = "github-runner";
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."github-runners/aws-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."github-runners/aws-secret-access-key"}
        '';
      };
      # Allow the runner user to use the nix daemon
      nix.settings.trusted-users = [ "github-runner" ];

      services.github-runners = builtins.listToAttrs (
        map (num: {
          name = "nixos-runner-${toString num}";
          value = {
            enable = true;
            # Run as a static user (disables DynamicUser). Required so the
            # disk-backed workDir below is a real path, not a /var/cache/private
            # symlink — see the users.users.github-runner comment above.
            user = "github-runner";
            group = "github-runner";
            # Default workDir is the systemd RuntimeDirectory under /run (tmpfs),
            # which is RAM-backed and small — builds fill it up. Use a disk-backed
            # CacheDirectory instead (see serviceOverrides), which systemd creates
            # and chowns to the runner user each start. It's a reconstructable
            # checkout (wiped each start), so cache, not state.
            workDir = workDirFor num;
            # Changing workDir/user triggers a new registration; without replace
            # the re-registration under the same name fails.
            replace = true;
            url = "https://github.com/britter/home-lab";
            tokenType = "access";
            tokenFile = config.sops.secrets."github-runners/pat".path;
            extraLabels = [
              "nixos"
              "x86_64"
            ];
            serviceOverrides = {
              # CacheDirectory for the workDir above. With a static user systemd
              # creates it as a real dir at /var/cache/github-runners/<name>
              # (no /private symlink), chowned to the runner user, writable under
              # ProtectSystem=strict.
              CacheDirectory = [ (cacheSubdir num) ];
              # CacheDirectory already implies its own BindPaths=; the module adds
              # a second, redundant BindPaths=[workDir] for custom workDirs. Clear
              # it so CacheDirectory manages the dir outright.
              BindPaths = lib.mkForce [ ];
              EnvironmentFile = [ config.sops.templates.state-backend-secrets.path ];
              Environment = [
                "SOPS_AGE_KEY_FILE=${config.sops.secrets."github-runners/age-key".path}"
              ];
            };
          };
        }) (lib.range 1 count)
      );
    };
}
