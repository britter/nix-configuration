{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.modules.sway;
in
{
  options.my.modules.sway = {
    enable = lib.mkEnableOption "sway";
  };

  config = lib.mkIf cfg.enable {
    # puts systemd init logs on tty1
    # so that tuigreet and systemd logs don't clobber each other
    boot.kernelParams = [ "console=tty1" ];

    # Allow swaylock to unlock the computer for us
    security.pam.services.swaylock = {
      text = "auth include login";
    };

    # bluetooth needs to be enabled for bluetuith to work
    hardware.bluetooth.enable = true;

    #xdg portal wlr is required for screensharing
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      config.common.default = "*";
    };

    services = {
      greetd = {
        enable = true;
        useTextGreeter = true;
        settings = {
          default_session = {
            command = ''
              ${lib.getExe pkgs.tuigreet} \
                --remember \
                --time \
                --asterisks \
                --cmd ${lib.getExe pkgs.sway}
            '';
          };
        };
      };

      # Required for automatically mounting USB devices
      devmon.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
    };
  };
}
