{ inputs, ... }:
{
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
      imports = [ inputs.noctalia.homeModules.default ];

      xdg.configFile."noctalia/colorschemes/${schemeName}/${schemeName}.json".text = builtins.toJSON {
        dark = variant config.catppuccin.flavor;
        light = variant "latte";
      };

      programs.noctalia-shell = {
        enable = true;
        package = pkgs.noctalia-shell;
        settings = {
          colorSchemes = {
            useWallpaperColors = false;
            predefinedScheme = schemeName;
          };
          bar = {
            outerCorners = false;
            widgets = {
              left = [
                { id = "Workspace"; }
                { id = "MediaMini"; }
              ];
              center = [
                { id = "Clock"; }
                { id = "NotificationHistory"; }
              ];
              right = [
                { id = "Tray"; }
                { id = "SystemMonitor"; }
                { id = "Battery"; }
                { id = "Volume"; }
                { id = "Brightness"; }
                {
                  id = "ControlCenter";
                  customIconPath = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
                }
              ];
            };
          };
          appLauncher = {
            terminalCommand = "${pkgs.ghostty} -e";
            enableClipboardHistory = true;
          };
          dock.enable = false;
          nightLight = {
            enabled = true;
            autoSchedule = false; # flip to true only once a location is configured
            nightTemp = "4000";
            dayTemp = "6500";
            manualSunrise = "06:30";
            manualSunset = "20:00";
          };
          sessionMenu = {
            enableCountdown = false;
            largeButtonsStyle = false;
            powerOptions = [
              {
                action = "lock";
                enabled = true;
                keybind = "l";
              }
              {
                action = "suspend";
                enabled = true;
                keybind = "s";
              }
              {
                action = "hibernate";
                enabled = true;
                keybind = "h";
              }
              {
                action = "reboot";
                enabled = true;
                keybind = "r";
              }
              {
                action = "logout";
                enabled = true;
                keybind = "e";
              }
              {
                action = "shutdown";
                enabled = true;
                keybind = "p";
              }
              {
                action = "rebootToUefi";
                enabled = false;
                keybind = "7";
              }
            ];
          };
        };
      };
    };
}
