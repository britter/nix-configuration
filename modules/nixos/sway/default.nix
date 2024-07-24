{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.sway;
in {
  options.my.modules.sway = {
    enable = lib.mkEnableOption "sway";
  };

  config = lib.mkIf cfg.enable {
    # puts systemd init logs on tty1
    # so that tuigreet and systemd logs don't clobber each other
    boot.kernelParams = ["console=tty1"];

    # Allow swaylock to unlock the computer for us
    security.pam.services.swaylock = {
      text = "auth include login";
    };

    services.greetd = {
      enable = true;
      vt = 2;
      settings = {
        default_session = {
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
              --remember \
              --time \
              --asterisks \
              --cmd ${pkgs.sway}/bin/sway
          '';
        };
      };
    };
  };
}