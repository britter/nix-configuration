_: {
  flake.factory.github-runners =
    { count }:
    {
      config,
      lib,
      ...
    }:
    let
      workDirFor = num: "/var/lib/github-runners/nixos-runner-${toString num}";
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

      # The runners use a disk-backed workDir (see below). The module binds this
      # path into the service namespace but does not create it, so it must exist
      # beforehand. Runners run as DynamicUser (runtime UID) but are members of
      # the github-runners group, so group-owned + 0770 lets them write & clean.
      systemd.tmpfiles.rules = map (num: "d ${workDirFor num} 0770 root github-runners - -") (
        lib.range 1 count
      );

      services.github-runners = builtins.listToAttrs (
        map (num: {
          name = "nixos-runner-${toString num}";
          value = {
            enable = true;
            # Default workDir is the systemd RuntimeDirectory under /run (tmpfs),
            # which is RAM-backed and small — builds fill it up. Use disk instead.
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
