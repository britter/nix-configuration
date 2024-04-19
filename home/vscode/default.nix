{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.vscode;
in {
  options.my.home.desktop.vscode = {
    enable = lib.mkEnableOption "vscode";
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
    };
  };
}
