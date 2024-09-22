{
  config,
  lib,
  pkgs,
  ...
}: let
  rofi = lib.getExe config.programs.rofi.finalPackage;
in {
  home.sessionVariables = {
    WL_PRESENT_DMENU = "${rofi} -dmenu -p present";
  };
  wayland.windowManager.sway = {
    wrapperFeatures.gtk = true;
    config = {
      terminal = "${pkgs.alacritty}/bin/alacritty";
      menu = "${rofi} -show drun -show-icons -pid";
      bars = [{command = "${pkgs.waybar}/bin/waybar";}];
      defaultWorkspace = "workspace number 1";
      fonts = {
        names = ["DejaVu Sans" "Font Awesome 6 Free"];
        size = 10.0;
      };
      colors = {
        background = "$base";
        focused = {
          background = "$base";
          border = "$lavender";
          childBorder = "$lavender";
          text = "$text";
          indicator = "$rosewater";
        };
        focusedInactive = {
          background = "$base";
          border = "$overlay0";
          childBorder = "$overlay0";
          text = "$text";
          indicator = "$rosewater";
        };
        unfocused = {
          background = "$base";
          border = "$overlay0";
          childBorder = "$overlay0";
          text = "$text";
          indicator = "$rosewater";
        };
        urgent = {
          background = "$base";
          border = "$peach";
          childBorder = "$peach";
          text = "$peach";
          indicator = "$overlay0";
        };
        placeholder = {
          background = "$base";
          border = "$overlay0";
          childBorder = "$overlay0";
          text = "$peach";
          indicator = "$overlay0";
        };
      };
      gaps.outer = 3;
      gaps.inner = 3;
      focus.followMouse = false;

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
        "*".bg = "${config.my.home.desktop.wallpapers.evening-sky} fill";
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

          # Custom modes
          "${mod}+Escape" = ''mode "system:  [l]ock  [s]leep  [h]ibernate  [r]eboot  [p]oweroff  [e]xit"'';
          "${mod}+p" = ''mode "present"'';
        };
      modes = {
        # redeclare resize mode in order not to override it
        resize = let
          inherit (config.wayland.windowManager) sway;
        in {
          "${sway.config.left}" = "resize shrink width 10 px";
          "${sway.config.down}" = "resize grow height 10 px";
          "${sway.config.up}" = "resize shrink height 10 px";
          "${sway.config.right}" = "resize grow width 10 px";
          "Left" = "resize shrink width 10 px";
          "Down" = "resize grow height 10 px";
          "Up" = "resize shrink height 10 px";
          "Right" = "resize grow width 10 px";
          "Escape" = "mode default";
          "Return" = "mode default";
        };
        "system:  [l]ock  [s]leep  [h]ibernate  [r]eboot  [p]oweroff  [e]xit" = {
          l = "exec ${pkgs.swaylock}/bin/swaylock";
          s = "exec systemctl suspend";
          h = "exec systemctl hibernate";
          r = "exec systemctl reboot";
          p = "exec systemctl poweroff";
          e = "exit";
          Return = "mode default";
          Escape = "mode default";
        };
        present = let
          wl-present = "${pkgs.wl-mirror}/bin/wl-present";
        in {
          # command starts mirroring
          m = ''mode "default"; exec ${wl-present} mirror'';
          # these commands modify an already running mirroring window
          o = ''mode "default"; exec ${wl-present} set-output'';
          r = ''mode "default"; exec ${wl-present} set-region'';
          "Shift+r" = ''mode "default"; exec ${wl-present} unset-region'';
          s = ''mode "default"; exec ${wl-present} set-scaling'';
          f = ''mode "default"; exec ${wl-present} toggle-freeze'';
          c = ''mode "default"; exec ${wl-present} custom'';
          # return to default mode
          "Escape" = "mode default";
          "Return" = "mode default";
        };
      };
      window.titlebar = false;
      window.border = 3;
      window.commands = [
        {
          criteria.app_id = ".*-floating";
          command = "floating enable";
        }
        {
          criteria.class = ".*";
          command = "inhibit_idle fullscreen";
        }
        {
          criteria.shell = "xwayland";
          command = "title_format \"%title :: %shell\"";
        }
        {
          criteria.app_id = "pavucontrol";
          command = "floating enable";
        }
        {
          criteria.app_id = "pavucontrol";
          command = "resize set 800 600";
        }
      ];
    };
  };
}
