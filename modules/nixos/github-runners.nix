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
      # github-runners are created with dynamic users.
      # setup a supplementary group to grant read access to
      # the PAT for generating a registration token.
      users.groups.github-runners = { };
      sops.secrets."github-runners/pat" = {
        group = "github-runners";
        mode = "0440";
      };
      sops.secrets."github-runners/age-key" = {
        group = "github-runners";
        mode = "0440";
      };
      sops.secrets."github-runners/aws-access-key-id" = {
        group = "github-runners";
        mode = "0440";
      };
      sops.secrets."github-runners/aws-secret-access-key" = {
        group = "github-runners";
        mode = "0440";
      };
      sops.templates."state-backend-secrets" = {
        owner = "root";
        group = "github-runners";
        mode = "0440";
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."github-runners/aws-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."github-runners/aws-secret-access-key"}
        '';
      };
      # Allow members of the github-runners group to use the nix daemon
      nix.settings.trusted-users = [ "@github-runners" ];

      services.github-runners = builtins.listToAttrs (
        map (num: {
          name = "nixos-runner-${toString num}";
          value = {
            enable = true;
            # Default workDir is the systemd RuntimeDirectory under /run (tmpfs),
            # which is RAM-backed and small — builds fill it up. Use a disk-backed
            # CacheDirectory instead (see serviceOverrides), which systemd creates
            # and chowns to the runner's dynamic user on every start. It's a
            # reconstructable checkout (wiped each start), so cache, not state.
            workDir = workDirFor num;
            # Changing workDir triggers a new registration; without replace the
            # re-registration under the same name fails.
            replace = true;
            url = "https://github.com/britter/home-lab";
            tokenType = "access";
            tokenFile = config.sops.secrets."github-runners/pat".path;
            extraLabels = [
              "nixos"
              "x86_64"
            ];
            serviceOverrides = {
              # CacheDirectory for the workDir above. systemd creates it on disk
              # under /var/cache and chowns it to the dynamic user each start, so
              # $HOME (= workDir) is owned by the runner and stays writable under
              # ProtectSystem=strict.
              CacheDirectory = [ (cacheSubdir num) ];
              SupplementaryGroups = [ "github-runners" ];
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
