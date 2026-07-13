{ inputs, ... }:
{
  flake.modules.nixos.noctalia = {
    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    # Pull noctalia from its binary cache instead of compiling it.
    nix.settings = {
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia = {
        enable = true;
        # The v5 home module registers no overlay, so pkgs.noctalia is absent;
        # take the package straight from the flake input.
        package = inputs.noctalia.packages.${pkgs.system}.default;
        settings = {
          theme = {
            source = "builtin";
            builtin = "Catppuccin";
          };
          bar.main = {
            start = [
              "workspaces"
              "media"
            ];
            center = [
              "clock"
              "notifications"
            ];
            end = [
              "tray"
              "sysmon"
              "battery"
              "volume"
              "brightness"
              "control-center"
            ];
          };
          dock.enabled = false;
          shell.session.actions = [
            {
              action = "lock";
              enabled = true;
              shortcut = "l";
            }
            {
              action = "suspend";
              enabled = true;
              shortcut = "s";
            }
            {
              action = "reboot";
              enabled = true;
              shortcut = "r";
            }
            {
              action = "logout";
              enabled = true;
              shortcut = "e";
            }
            {
              action = "shutdown";
              enabled = true;
              shortcut = "p";
            }
          ];
        };
      };
    };
}
