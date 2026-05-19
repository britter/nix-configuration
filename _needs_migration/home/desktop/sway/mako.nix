{
  config,
  lib,
  ...
}:
let
  cfg = config.my.home.desktop.sway.mako;
in
{
  options.my.home.desktop.sway.mako = {
    enable = lib.mkEnableOption "mako";
  };
  config = lib.mkIf cfg.enable {
    services.mako = {
      # test with notify-send.
      enable = true;
      settings = {
        "mode=do-not-disturb" = {
          invisible = 1;
        };
        default-timeout = 4500;
        ignore-timeout = true;
      };
    };
  };
}
