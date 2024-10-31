{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.sway.swayidle;
in {
  options.my.home.desktop.sway.swayidle = {
    enable = lib.mkEnableOption "swayidle";
  };
  config = lib.mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 295;
          command = "${pkgs.libnotify}/bin/notify-send 'Locking in 5 seconds' -t 5000";
        }
        {
          timeout = 300;
          command = "${config.programs.swaylock.package}/bin/swaylock";
        }
        {
          timeout = 600;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
      events = [
        {
          event = "before-sleep";
          command = "${config.programs.swaylock.package}/bin/swaylock";
        }
      ];
    };
  };
}
