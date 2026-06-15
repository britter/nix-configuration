{ inputs, ... }:
{
  flake.modules.nixos.noctalia = {
    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
  };

  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia = {
        enable = true;
        settings = {
          bar = {
            outerCorners = false;
            widgets = {
              left = [
                { id = "Workspace"; }
                { id = "MediaMini"; }
              ];
              center = [
                { id = "Clock"; }
                { id = "NotificationHistory"; }
              ];
              right = [
                { id = "Tray"; }
                { id = "SystemMonitor"; }
                { id = "Battery"; }
                { id = "Volume"; }
                { id = "Brightness"; }
                { id = "ControlCenter"; }
              ];
            };
          };
          appLauncher = {
            terminalCommand = "${pkgs.ghostty} -e";
            enableClipboardHistory = true;
          };
          dock.enable = false;
          sessionMenu = {
            enableCountdown = false;
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
    };
}
