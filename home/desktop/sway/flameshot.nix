{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.desktop.sway.flameshot;
in {
  options.my.home.desktop.sway.flameshot = {
    enable = lib.mkEnableOption "flameshot";
  };

  config = lib.mkIf cfg.enable {
    services.flameshot.enable = true;
  };
}
