{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.desktop.mako;
in {
  options.my.home.desktop.mako = {
    enable = lib.mkEnableOption "mako";
  };
  config = lib.mkIf cfg.enable {
    services.mako = {
      # test with notify-send.
      enable = true;
      defaultTimeout = 4500;
      ignoreTimeout = true;
      extraConfig = ''
        [mode=do-not-disturb]
        invisible=1
      '';
    };
  };
}
