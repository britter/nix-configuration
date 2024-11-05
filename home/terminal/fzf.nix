{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.fzf;
in {
  options.my.home.terminal.fzf = {
    enable = lib.mkEnableOption "fzf";
  };
  config = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      defaultCommand = "${pkgs.ripgrep}/bin/rg --files";
    };
  };
}
