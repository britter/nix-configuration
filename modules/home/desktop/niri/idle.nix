{
  flake.modules.homeManager.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      lockCmd = "${lib.getExe config.programs.noctalia.package} msg session lock";
    in
    {
      # Despite the name, swayidle is a plain ext-idle-notify client and is
      # not tied to sway. niri has no idle handling of its own; it only
      # honours the idle-inhibit requests applications make, so there is no
      # compositor-side equivalent of sway's `inhibit_idle fullscreen`.
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 295;
            command = "${lib.getExe pkgs.libnotify} 'Locking in 5 seconds' -t 5000";
          }
          {
            timeout = 300;
            command = lockCmd;
          }
          {
            timeout = 600;
            command = "${lib.getExe' pkgs.systemd "systemctl"} suspend";
          }
        ];
        events.before-sleep = lockCmd;
      };
    };
}
