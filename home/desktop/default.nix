{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop;
in {
  imports = [
    ../gnome
    ../joplin
    ../firefox
    ../alacritty
    ../vscode
  ];

  options.my.home.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    # software not available as Home Manager module
    home.packages = with pkgs; [
      jetbrains.idea-community
      fractal-next
      logseq
    ];

    my.home.desktop = {
      gnome.enable = true;
      joplin.enable = true;
      firefox.enable = true;
      alacritty.enable = true;
      vscode.enable = true;
    };
  };
}
