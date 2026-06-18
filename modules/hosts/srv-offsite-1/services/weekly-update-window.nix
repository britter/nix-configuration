_: {
  # weekly comin update window
  # Since we can not coordinate comins fetch / deploy cycle with system shutdown, we wake the system
  # once per week for 30 minutes so it can run an update.
  # This is required, because most of the time the minIO sync will run much faster then the time required
  # to fetch config changes, eval config, and update the system, resulting in no updates being applied
  # during nightly sync wake ups.
  # https://github.com/nlewo/comin/issues/104
  flake.modules.nixos.weekly-update-window-on-srv-offsite-1 =
    { pkgs, ... }:
    {
      systemd.timers.weekly-update-wakeup = {
        description = "Weekly timer to wake up the system for the Comin update window";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Wed 03:00";
          Persistent = true;
          WakeSystem = true;
        };
      };
      systemd.services.weekly-update-wakeup = {
        description = "Sleeps for 30 minutes, then suspends the system again";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/sleep 30m";
          ExecStartPost = "${pkgs.systemd}/bin/systemctl suspend";
        };
      };
    };
}
