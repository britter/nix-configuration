{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.desktop.firefox;
in {
  options.my.home.desktop.firefox = {
    enable = lib.mkEnableOption "firefox";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox.enable = true;
  };
}
