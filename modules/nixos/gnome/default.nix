{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.my.modules.gnome;
in {
  options.my.modules.gnome = {
    enable = lib.mkEnableOption "GNOME";
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    # Enable touchpad support
    services.libinput.enable = true;

    environment.gnome.excludePackages =
      (with pkgs; [
        gnome-photos
        gnome-tour
      ])
      ++ (with pkgs.gnome; [
        cheese # webcam tool
        gnome-music
        epiphany # web browser
        geary # email reader
        gnome-characters
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
        yelp # Help view
        gnome-contacts
        gnome-initial-setup
      ]);

    environment.systemPackages = with pkgs; [
      gnomeExtensions.blur-my-shell
      gnomeExtensions.custom-hot-corners-extended
      gnomeExtensions.night-theme-switcher
      xsel # Access to X server clipboard, required for helix clipboard integration
    ];

    programs.dconf.enable = true;
  };
}
