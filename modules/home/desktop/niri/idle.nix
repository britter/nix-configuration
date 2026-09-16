_: {
  flake.modules.homeManager.noctalia = {
    # niri has no idle handling of its own; it only honours the idle-inhibit
    # requests applications make. Noctalia's idle service is an
    # ext_idle_notify client (like swayidle was) and respects those
    # inhibitors, so no separate idle daemon is needed.
    programs.noctalia.settings.idle = {
      # Fullscreen dim shown before each behaviour fires, replacing the
      # "locking in 5 seconds" notification swayidle used to send. Input
      # during the fade cancels the pending action, so the timeouts below
      # are 5s short of when the action actually happens.
      pre_action_fade_seconds = 5.0;

      behavior = {
        lock.timeout = 295;
        lock.action = "lock";

        # lock_before_suspend defaults to true, so this locks first even
        # though the lock behaviour above has already fired.
        suspend.timeout = 595;
        suspend.action = "suspend";
      };
    };

    # Lid close and other logind-initiated sleep lock via noctalia's
    # PrepareForSleep integration. Explicit session-menu actions must use
    # lock_and_suspend (see noctalia.nix) since plain suspend skips the lock.
  };
}
