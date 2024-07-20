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

        input = {
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
          };
          "type:keyboard" = {
            xkb_options = "compose:caps";
          };
        };

        output = {
          "*".bg = "${../desktop/wallpapers/moebius-wallpaper-light.png} fill";
        };

        modifier = "Mod4";
        keybindings = let
          mod = config.wayland.windowManager.sway.config.modifier;
        in
          lib.mkOptionDefault {
            # for defaults, see https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/i3-sway/sway.nix

            # Override moving containers to also switch to that workspace
            "${mod}+Shift+1" = "move container to workspace number 1; workspace number 1";
            "${mod}+Shift+2" = "move container to workspace number 2; workspace number 2";
            "${mod}+Shift+3" = "move container to workspace number 3; workspace number 3";
            "${mod}+Shift+4" = "move container to workspace number 4; workspace number 4";
            "${mod}+Shift+5" = "move container to workspace number 5; workspace number 5";
            "${mod}+Shift+6" = "move container to workspace number 6; workspace number 6";
            "${mod}+Shift+7" = "move container to workspace number 7; workspace number 7";
            "${mod}+Shift+8" = "move container to workspace number 8; workspace number 8";
            "${mod}+Shift+9" = "move container to workspace number 9; workspace number 9";
            "${mod}+Shift+0" = "move container to workspace number 10; workspace number 10";
          };
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
