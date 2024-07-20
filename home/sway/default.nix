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
        left = "h";
        down = "j";
        up = "k";
        right = "l";

        input = {
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
          };
        };

        output = {
          "*".bg = "${../desktop/wallpapers/moebius-wallpaper-light.png} fill";
        };

        keybindings = let
          swayCfg = config.wayland.windowManager.sway.config;
          mod = swayCfg.modifier;
          inherit
            (swayCfg)
            terminal
            menu
            left
            down
            up
            right
            ;
        in {
          "${mod}+Return" = "exec ${terminal}";
          "${mod}+Shift+q" = "kill";
          "${mod}+d" = "exec ${menu}";

          "${mod}+${left}" = "focus left";
          "${mod}+${down}" = "focus down";
          "${mod}+${up}" = "focus up";
          "${mod}+${right}" = "focus right";

          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";

          "${mod}+Shift+${left}" = "move left";
          "${mod}+Shift+${down}" = "move down";
          "${mod}+Shift+${up}" = "move up";
          "${mod}+Shift+${right}" = "move right";

          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";

          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";
          "${mod}+0" = "workspace number 10";

          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";
          "${mod}+Shift+0" = "move container to workspace number 10";
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
