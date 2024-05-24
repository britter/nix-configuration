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
      joplin-desktop
      fractal-next
    ];

    my.home.desktop = {
      gnome.enable = true;
      firefox.enable = true;
      alacritty.enable = true;
      vscode.enable = true;
    };
  };
}
