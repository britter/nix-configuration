{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.desktop.sway.swaylock;
in {
  options.my.home.desktop.sway.swaylock = {
    enable = lib.mkEnableOption "swaylock";
  };
  config = lib.mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      settings = {
        image = "${../wallpapers/moebius-wallpaper-dark.jpg}";
        daemonize = true;
        ignore-empty-password = true;
      };
    };
  };
}
