{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.desktop.swaylock;
in {
  options.my.home.desktop.swaylock = {
    enable = lib.mkEnableOption "swaylock";
  };
  config = lib.mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      settings = {
        image = "${../desktop/wallpapers/moebius-wallpaper-dark.jpg}";
        daemonize = true;
        ignore-empty-password = true;
      };
    };
  };
}
