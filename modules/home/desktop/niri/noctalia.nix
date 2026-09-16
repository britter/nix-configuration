{ config, ... }:
let
  outer = config;

  # The color roles noctalia renders its UI from, in the snake_case names the
  # greeter expects in [appearance.palette]. Stylix has no greeter target, so
  # this mirrors the mapping its noctalia target applies to the shell.
  roles = c: {
    primary = c.base0D;
    on_primary = c.base00;
    secondary = c.base0E;
    on_secondary = c.base00;
    tertiary = c.base0C;
    on_tertiary = c.base00;
    error = c.base08;
    on_error = c.base00;
    surface = c.base00;
    on_surface = c.base05;
    surface_variant = c.base01;
    on_surface_variant = c.base04;
    outline = c.base03;
    shadow = c.base00;
    hover = c.base0C;
    on_hover = c.base00;
  };
in
{
  flake.modules.nixos.noctalia =
    { config, ... }:
    {
      # Single import site for the stylix NixOS module, which the greeter
      # needs at system level to derive its palette.
      imports = [ outer.flake.modules.nixos.theme ];

      networking.networkmanager.enable = true;
      hardware.bluetooth.enable = true;
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;

      # Login screen. Everything appearance related is declared here rather
      # than pushed over from the running shell with noctalia's "Sync
      # Greeter", which writes mutable state into /var/lib. A complete
      # [appearance.palette] in greeter.toml takes precedence over that state.
      services.displayManager.noctalia-greeter = {
        enable = true;

        cursorTheme = {
          inherit (config.stylix.cursor) package name;
        };

        settings = {
          # Session picker label, not the .desktop id.
          session.default = "Niri";
          user.default = "bene";
          cursor.size = config.stylix.cursor.size;
          keyboard.layout = "us";
          appearance = {
            # Selects the palette declared here instead of one of the
            # built-in schemes.
            scheme = "Synced";
            theme_mode = "dark";
            font_family = config.stylix.fonts.sansSerif.name;
            palette = roles config.lib.stylix.colors.withHashtag;
            wallpaper = {
              path = config.stylix.image;
              fill_mode = "crop";
            };
          };
        };
      };
    };

  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    {
      programs.noctalia = {
        enable = true;

        # niri runs as a systemd session, so the shell is bound to
        # graphical-session.target rather than spawned by the compositor.
        systemd.enable = true;

        settings = {
          bar.default = {
            # Vertical, so the workspace pills stack along the same axis as
            # niri's per-monitor workspace list. start/center/end become
            # top/center/bottom.
            position = "left";

            start = [
              "control-center"
              "workspaces"
              "media"
            ];
            center = [
              "clock"
              "notifications"
            ];
            end = [
              "tray"
              "systmon"
              "battery"
              "volume"
              "brightness"
            ];
          };
          widget = {
            battery.show_label = false;
            volume.show_label = false;
            brightness.show_label = false;
            media.hide_when_no_media = true;
            control-center.custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
          };
          # appLauncher = {
          #   terminalCommand = "${pkgs.ghostty} -e";
          #   enableClipboardHistory = true;
          # };
          location.auto_locate = true;
          shell.session = {
            grid_columns = 1;
            actions = [
              {
                action = "lock";
                shortcut = "l";
              }
              {
                action = "suspend";
                shortcut = "s";
              }
              {
                action = "command";
                label = "Hibernate";
                glyph = "zz";
                command = "systemctl hibernate";
                shortcut = "h";
              }
              {
                action = "reboot";
                shortcut = "r";
              }
              {
                action = "logout";
                shortcut = "e";
              }
              {
                action = "shutdown";
                shortcut = "p";
              }
            ];
          };
        };
      };
    };
}
