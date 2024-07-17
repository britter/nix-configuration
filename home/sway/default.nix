{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.sway;
  cursor = {
    theme = "Adwaita";
    size = 14;
  };
in {
  options.my.home.desktop.sway = {
    enable = lib.mkEnableOption "sway";
  };

  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
    };

    wayland.windowManager.sway = {
      enable = true;
      config = {
        terminal = "${pkgs.alacritty}/bin/alacritty";
        menu = "${lib.getExe config.programs.rofi.finalPackage} -show drun -show-icons -pid";
        bars = [{command = "${pkgs.waybar}/bin/waybar";}];

        modifier = "Mod4";
      };
    };

    home.pointerCursor = {
      name = cursor.theme;
      package = pkgs.gnome.adwaita-icon-theme;
      inherit (cursor) size;
    };

    gtk.cursorTheme = {
      name = cursor.theme;
      inherit (cursor) size;
    };
  };
}
