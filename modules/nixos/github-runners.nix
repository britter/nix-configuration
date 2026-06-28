_: {
  flake.factory.github-runners =
    { count }:
    { config, lib, ... }:
    {
      # github-runners are created with dynamic users.
      # setup a supplementary group to grant read access to
      # the PAT for generating a registration token.
      users.groups.github-runners = { };
      sops.secrets."github-runners/pat" = {
        group = "github-runners";
        mode = "0440";
      };

      # Allow members of the github-runners group to use the nix daemon
      nix.settings.trusted-users = [ "@github-runners" ];

      services.github-runners = builtins.listToAttrs (
        map (num: {
          name = "nixos-runner-${toString num}";
          value = {
            enable = true;
            url = "https://github.com/britter/home-lab";
            tokenType = "access";
            tokenFile = config.sops.secrets."github-runners/pat".path;
            extraLabels = [
              "nixos"
              "x86_64"
            ];
            serviceOverrides = {
              SupplementaryGroups = [ "github-runners" ];
            };
          };
        }) (lib.range 1 count)
      );
    };
}
