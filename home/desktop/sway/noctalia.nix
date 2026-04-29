{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.home.desktop.sway.noctalia-shell;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];
  options.my.home.desktop.sway.noctalia-shell = {
    enable = lib.mkEnableOption "noctalia";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia-shell = {
      enable = true;
      settings = {
        bar = {
          outerCorners = false;
          widgets = {
            left = [
              {
                id = "Workspace";
              }
              {
                id = "MediaMini";
              }
            ];
            center = [
              {
                id = "Clock";
              }
              {
                id = "NotificationHistory";
              }
            ];
            right = [
              {
                id = "Tray";
              }
              {
                id = "SystemMonitor";
              }
              {
                id = "Battery";
              }
              {
                id = "Volume";
              }
              {
                id = "Brightness";
              }
              {
                id = "ControlCenter";
              }
            ];
          };
        };
        appLauncher.terminalCommand = "${pkgs.ghostty} -e";
        sessionMenu = {
          largeButtonsStyle = false;
          powerOptions = [
            {
              action = "lock";
              enabled = true;
              keybind = "l";
            }
            {
              action = "suspend";
              enabled = true;
              keybind = "s";
            }
            {
              action = "hibernate";
              enabled = true;
              keybind = "h";
            }
            {
              action = "reboot";
              enabled = true;
              keybind = "r";
            }
            {
              action = "logout";
              enabled = true;
              keybind = "e";
            }
            {
              action = "shutdown";
              enabled = true;
              keybind = "p";
            }
            {
              action = "rebootToUefi";
              enabled = false;
              keybind = "7";
            }
          ];
        };
      };
    };
    home.file.".cache/noctalia/wallpapers.json" = {
      text = builtins.toJSON {
        defaultWallpaper = "${config.my.home.desktop.wallpapers.evening-sky}";
      };
    };
  };
}
