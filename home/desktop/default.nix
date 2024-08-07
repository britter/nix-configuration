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
      vscode.enable = true;
    };
  };
}
