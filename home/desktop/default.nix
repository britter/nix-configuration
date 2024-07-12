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
    ../gnome
    ../intellij
    ../vscode
  ];

  options.my.home.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    # software not available as Home Manager module
    home.packages = with pkgs; [
      fractal-next
      logseq
    ];

    my.home.desktop = {
      alacritty.enable = true;
      firefox.enable = true;
      gnome.enable = true;
      intellij = {
        enable = true;
        plugins = ["asciidoc" "protocol-buffers"];
      };
      vscode.enable = true;
    };
  };
}
