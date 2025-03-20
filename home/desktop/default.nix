{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop;
in {
  imports = [
    ./alacritty
    ./firefox
    ./intellij
    ./sway
    ./vscode
    ./wallpapers
  ];

  options.my.home.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    # software not available as Home Manager module
    home.packages = with pkgs; [
      audacity
      bitwarden-desktop
      calibre
      libreoffice
      obsidian
      vlc
    ];

    catppuccin.cursors = {
      enable = true;
      accent = "dark";
    };

    xdg = {
      mime.enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = ["org.gnome.Evince.desktop"];
          "inode/directory" = ["org.gnome.Nautilus.desktop"];
        };
      };
    };

    my.home.desktop = {
      alacritty.enable = true;
      firefox.enable = true;
      librewolf.enable = true;
      intellij = {
        enable = true;
        plugins = ["asciidoc" "protocol-buffers"];
      };
      sway.enable = true;
      vscode.enable = true;
    };

    # this requires security.polkit.enable and services.gnome.gnome-keyring.enable in the host config
    # in order to store the authentication data across reboots.
    services.nextcloud-client.enable = true;
  };
}
