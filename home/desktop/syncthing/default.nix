{
  config,
  lib,
  ...
}:
let
  cfg = config.my.home.desktop.syncthing;
in
{
  options.my.home.desktop.syncthing = {
    enable = lib.mkEnableOption "syncthing";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      tray = true;
    };
  };
}
