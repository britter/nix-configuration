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
  imports = [ ];

  options.my.home.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bitwarden-desktop
      obsidian
    ];

    catppuccin = {
      cursors = {
        enable = true;
        accent = "dark";
      };
      librewolf.profiles.default.enable = false;
    };

    # this requires security.polkit.enable and services.gnome.gnome-keyring.enable in the host config
    # in order to store the authentication data across reboots.
    services.nextcloud-client.enable = true;
  };
}
