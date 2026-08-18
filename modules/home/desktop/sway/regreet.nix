{
  flake.modules.nixos.regreet =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # The programs.regreet module only wires up the cage launch. Run ReGreet
      # under sway instead (more reliable than cage, and the compositor already
      # used here). See ReGreet README "Set as default session".
      greeterSwayConfig = pkgs.writeText "greetd-sway-config" ''
        exec "${lib.getExe config.programs.regreet.package}; swaymsg exit"
      '';
    in
    {
      programs.regreet = {
        enable = true;
        theme = {
          package = pkgs.catppuccin-gtk.override {
            accents = [ "red" ]; # matches sway's $red borders
            variant = "macchiato";
          };
          name = "catppuccin-macchiato-red-standard";
        };
        cursorTheme = {
          package = pkgs.catppuccin-cursors.macchiatoDark;
          name = "catppuccin-macchiato-dark-cursors";
        };
        font = {
          package = pkgs.dejavu_fonts; # matches the sway UI font
          name = "DejaVu Sans";
          size = 12;
        };
        settings = {
          background = {
            path = "${pkgs.wallpapers}/landscapes/Clearday.jpg";
            fit = "Cover";
          };
          GTK.application_prefer_dark_theme = true;
        };
      };

      # Override the module's default cage launch with sway.
      services.greetd.settings.default_session.command =
        "${pkgs.dbus}/bin/dbus-run-session ${lib.getExe pkgs.sway} --config ${greeterSwayConfig}";
    };
}
