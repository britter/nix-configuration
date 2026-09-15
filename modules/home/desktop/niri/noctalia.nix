{ config, lib, ... }:
let
  outer = config;

  # Same palette source catppuccin/nix uses internally, so the shell and the
  # greeter track the flavor configured in modules/home/desktop/theme.nix.
  colorsOf =
    source: flavor:
    lib.mapAttrs (_: v: v.hex) (lib.importJSON "${source}/palette.json").${flavor}.colors;

  # The color roles noctalia renders its UI from. The greeter consumes them
  # under exactly these snake_case names in [appearance.palette]; the shell
  # wants the same roles as mCamelCase keys.
  roles = accent: p: {
    primary = p.${accent};
    on_primary = p.base;
    secondary = p.lavender;
    on_secondary = p.base;
    tertiary = p.sky;
    on_tertiary = p.base;
    error = p.red;
    on_error = p.base;
    surface = p.base;
    on_surface = p.text;
    surface_variant = p.surface0;
    on_surface_variant = p.subtext0;
    outline = p.overlay0;
    shadow = p.crust;
    hover = p.surface1;
    on_hover = p.text;
  };
  shellKey = name: "m" + lib.concatMapStrings lib.toSentenceCase (lib.splitString "_" name);
in
{
  flake.modules.nixos.noctalia =
    {
      config,
      pkgs,
      ...
    }:
    {
      # Single import site for the catppuccin NixOS module, which the greeter
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
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
        };

        settings = {
          # Session picker label, not the .desktop id.
          session.default = "Niri";
          user.default = "bene";
          cursor.size = 32;
          keyboard.layout = "us";
          appearance = {
            # Selects the palette below instead of one of the built-in schemes.
            scheme = "Synced";
            theme_mode = "dark";
            palette = roles config.catppuccin.accent (
              colorsOf config.catppuccin.sources.palette config.catppuccin.flavor
            );
            wallpaper = {
              path = "${pkgs.wallpapers}/landscapes/Clearday.jpg";
              fill_mode = "crop";
            };
          };
        };
      };
    };

  flake.modules.homeManager.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Noctalia only ships Catppuccin Mocha, so generate the configured
      # flavor as a custom scheme instead.
      variant =
        flavor:
        let
          p = colorsOf config.catppuccin.sources.palette flavor;
        in
        lib.mapAttrs' (name: lib.nameValuePair (shellKey name)) (roles config.catppuccin.accent p)
        // {
          terminal = {
            normal = {
              black = p.surface1;
              inherit (p)
                red
                green
                yellow
                blue
                ;
              magenta = p.pink;
              cyan = p.teal;
              white = p.subtext1;
            };
            bright = {
              black = p.surface2;
              inherit (p)
                red
                green
                yellow
                blue
                ;
              magenta = p.pink;
              cyan = p.teal;
              white = p.subtext0;
            };
            foreground = p.text;
            background = p.base;
            selectionFg = p.text;
            selectionBg = p.surface2;
            cursorText = p.base;
            cursor = p.rosewater;
          };
        };
      schemeName = "Catppuccin ${lib.toSentenceCase config.catppuccin.flavor}";
    in
    {
      xdg.configFile."noctalia/palettes/${schemeName}.json".text = builtins.toJSON {
        dark = variant config.catppuccin.flavor;
        light = variant "latte";
      };

      programs.noctalia = {
        enable = true;

        # niri runs as a systemd session, so the shell is bound to
        # graphical-session.target rather than spawned by the compositor.
        systemd.enable = true;

        settings = {
          # Doesn't seem to work
          theme = {
            source = "custom";
            custom_palette = schemeName;
          };
          wallpaper = {
            default.path = "${pkgs.wallpapers}/landscapes/Clearday.jpg";
            directory = "${pkgs.wallpapers}";
          };
          bar.default = {
            # Vertical, so the workspace pills stack along the same axis as
            # niri's per-monitor workspace list. start/center/end become
            # top/center/bottom.
            position = "left";

            start = [
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
              "control-center"
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
