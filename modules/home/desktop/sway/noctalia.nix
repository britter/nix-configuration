_: {
  flake.modules.nixos.noctalia = {
    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
  };

  flake.modules.homeManager.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Same palette source catppuccin/nix uses internally, so the shell tracks
      # the flavor configured in modules/home/catppuccin.nix. Noctalia only
      # ships Catppuccin Mocha, so generate the configured flavor as a custom
      # scheme instead.
      palettes = lib.importJSON "${config.catppuccin.sources.palette}/palette.json";
      variant =
        flavor:
        let
          p = lib.mapAttrs (_: v: v.hex) palettes.${flavor}.colors;
        in
        {
          mPrimary = p.${config.catppuccin.accent};
          mOnPrimary = p.base;
          mSecondary = p.lavender;
          mOnSecondary = p.base;
          mTertiary = p.sky;
          mOnTertiary = p.base;
          mError = p.red;
          mOnError = p.base;
          mSurface = p.base;
          mOnSurface = p.text;
          mSurfaceVariant = p.surface0;
          mOnSurfaceVariant = p.subtext0;
          mOutline = p.overlay0;
          mShadow = p.crust;
          mHover = p.surface1;
          mOnHover = p.text;
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
        settings = {
          # Doesn't seem to work
          theme = {
            source = "custom";
            custom_palette = schemeName;
          };
          bar.default = {
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
