{
  flake.modules.homeManager.sway =
    { config, pkgs, ... }:
    {
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
        events.before-sleep = "${config.programs.swaylock.package}/bin/swaylock";
      };
    };
}
