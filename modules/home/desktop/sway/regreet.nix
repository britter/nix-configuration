{
  flake.modules.nixos.regreet =
    { config, pkgs, ... }:
    {
      # ReGreet finds sessions via XDG_DATA_DIRS; sway ships share/wayland-sessions/sway.desktop
      # (Exec=sway — the same unwrapped system sway the old tuigreet --cmd launched).
      environment.systemPackages = [ pkgs.sway ];

      programs.regreet = {
        enable = true; # auto-configures services.greetd + the cage command
        theme = {
          # catppuccin-gtk is broken on this nixpkgs pin (python catppuccin build
          # fails against matplotlib 3.11); magnetic-catppuccin-gtk builds cleanly.
          package = pkgs.magnetic-catppuccin-gtk.override {
            accent = [ "red" ]; # matches sway's $red borders
            tweaks = [ "macchiato" ];
          };
          name = "Catppuccin-GTK-Red-Dark-Macchiato";
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
            path = config.systemConstants.wallpaper;
            fit = "Cover";
          };
          GTK.application_prefer_dark_theme = true;
        };
      };
    };
}
