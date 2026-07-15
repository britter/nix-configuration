{
  flake.modules.homeManager.sway =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      lockCmd = "${lib.getExe config.programs.noctalia-shell.package} ipc call lockScreen lock";
    in
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
            command = lockCmd;
          }
          {
            timeout = 600;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];
        events.before-sleep = lockCmd;
      };
    };
}
