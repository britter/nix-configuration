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
      bitwarden-desktop
      libreoffice
      logseq
      vlc
    ];

    catppuccin.pointerCursor = {
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
      intellij = {
        enable = true;
        plugins = ["asciidoc" "protocol-buffers"];
      };
      sway.enable = true;
      vscode.enable = true;
    };
  };
}
