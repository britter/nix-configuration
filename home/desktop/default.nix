{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop;
in {
  imports = [
    ../alacritty
    ../firefox
    ../intellij
    ../mako
    ../sway
    ../swayidle
    ../swaylock
    ../vscode
    ../waybar
  ];

  options.my.home.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    # software not available as Home Manager module
    home.packages = with pkgs; [
      cinny-desktop
      logseq
    ];

    my.home.desktop = {
      alacritty.enable = true;
      firefox.enable = true;
      intellij = {
        enable = true;
        plugins = ["asciidoc" "protocol-buffers"];
      };
      sway.enable = true;
      # TODO make this part of the sway module
      mako.enable = true;
      swayidle.enable = true;
      swaylock.enable = true;
      waybar.enable = true;

      vscode.enable = true;
    };
  };
}
