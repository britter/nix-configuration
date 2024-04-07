{pkgs, ...}: {
  dconf.settings = {
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
}
