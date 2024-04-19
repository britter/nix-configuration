{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.gnome;
in {
  options.my.home.desktop.gnome = {
    enable = lib.mkEnableOption "gnome";
  };

  config = lib.mkIf cfg.enable {
    dconf.settings = {
      "org/gnome/desktop/background" = let
        light-bg = ../desktop/wallpapers/moebius-wallpaper-light.png;
        dark-bg = ../desktop/wallpapers/moebius-wallpaper-dark.jpg;
      in {
        picture-uri = "file://${light-bg}";
        picture-uri-dark = "file://${dark-bg}";
      };
      # set right alt as compose key for composing special letters suchs as umlauts
      "org/gnome/desktop/input-sources" = {
        xkb-options = ["terminate:ctrl_alt_bksp" "lv3:ralt_switch" "compose:ralt"];
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
      };
      "org/gnome/shell" = {
        favorite-apps = [
          "org.gnome.Calendar.desktop"
          "org.gnome.Nautilus.desktop"
          "firefox.desktop"
          "Alacritty.desktop"
          "org.gnome.Fractal.desktop"
        ];

        disable-user-extensions = false;
        enabled-extensions = [
          "custom-hot-corners-extended@G-dH.github.com"
          "nightthemeswitcher@romainvigier.fr"
          "blur-my-shell@aunetx"
        ];
      };
      # required by night theme switcher to determine time for sunrise and sunset
      "org/gnome/system/location" = {
        enabled = true;
      };
      "org/gnome/shell/extensions/custom-hot-corners-extended/monitor-0-bottom-left-0" = {
        action = "lock-screen";
      };
    };
  };
}
