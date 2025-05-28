{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.home.desktop.sway.waybar;
in
{
  options.my.home.desktop.sway.waybar = {
    enable = lib.mkEnableOption "waybar";
  };
  config = lib.mkIf cfg.enable {
    catppuccin.waybar.mode = "createLink";
    programs.waybar = {
      enable = true;
      systemd.target = "sway-session.target";
      style = ./waybar.css;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;

          modules-left = [
            "sway/workspaces"
            "sway/mode"
          ];
          modules-center = [
            "clock"
          ];
          modules-right = [
            "tray"
            "bluetooth"
            "network"
            "battery"
            "cpu"
            "memory"
            "pulseaudio"
          ];

          "clock" = {
            # See https://fmt.dev/latest/syntax/#chrono-format-specifications
            format = "{:%a, %b %d - %R}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc6d9'><b>{}</b></span>";
                weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                today = "<span color='#ff6699'><b><u>{}</u></b></span>";
              };
            };
          };

          "cpu" = {
            interval = 2;
            format = "{usage}% ";
            tooltip = false;
            states = {
              warning = 70;
              critical = 90;
            };
            on-click = "swaymsg exec \"${lib.getExe pkgs.alacritty} --class Alacritty-floating -e btop\"";
          };

          "memory" = {
            interval = 2;
            format = "{}% ";
            tooltip-format = "{used:0.1f}G / {total:0.1f}G";
            states = {
              warning = 70;
              critical = 90;
            };
            on-click = "swaymsg exec \"${lib.getExe pkgs.alacritty} --class Alacritty-floating -e btop\"";
          };

          "network" = {
            interval = 10;
            format = "";
            tooltip-format = ''
               {ifname} via {gwaddr}
               {essid} ({signalStrength}%)
               {bandwidthDownBytes}  {bandwidthUpBytes}
            '';
            on-click = "swaymsg exec \"${lib.getExe pkgs.alacritty} --class Alacritty-floating -e nmtui-connect\"";
          };

          "bluetooth" = {
            format = "";
            format-off = "";
            format-disabled = "";
            format-connected = " {num_connections}";
            tooltip-format = "{controller_alias}\t{controller_address}";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            on-click-right = "bash -c \"if rfkill list bluetooth|grep -q 'yes$';then rfkill unblock bluetooth;else rfkill block bluetooth;fi\"";
            on-click = "swaymsg exec \"${lib.getExe pkgs.alacritty} --class Alacritty-floating -e ${lib.getExe pkgs.bluetuith}\"";
          };

          "pulseaudio" = {
            scroll-step = 5;
            format = "{volume}% {icon} {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = "{volume}% ";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              default = [
                ""
                ""
                ""
              ];
            };
            "on-click" = "${lib.getExe pkgs.pavucontrol}";
          };

          "battery" = {
            interval = 60;
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };

          "sway/mode" = {
            format = "<span style=\"italic\">{}</span>";
            tooltip = false;
          };

          "sway/language" = {
            on-click = "swaymsg input type:keyboard xkb_switch_layout next";
            tooltip = false;
          };
        };
      };
    };
  };
}
