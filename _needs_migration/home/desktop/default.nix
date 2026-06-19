{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.desktop;
in
{
  imports = [
    ./browser
    ./calibre
  ];

  options.my.home.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    # software not available as Home Manager module
    home.packages = with pkgs; [
      audacity
      bitwarden-desktop
      chromium
      gimp
      libreoffice
      obsidian
      vlc
    ];

    catppuccin = {
      cursors = {
        enable = true;
        accent = "dark";
      };
      librewolf.profiles.default.enable = false;
    };

    my.home.desktop = {
      browser.enable = true;
      calibre.enable = true;
    };

    # this requires security.polkit.enable and services.gnome.gnome-keyring.enable in the host config
    # in order to store the authentication data across reboots.
    services.nextcloud-client.enable = true;
  };
}
