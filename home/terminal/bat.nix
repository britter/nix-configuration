{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.bat;
in {
  options.my.home.terminal.bat = {
    enable = lib.mkEnableOption "bat";
  };

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      catppuccin = {
        enable = true;
        flavor = "macchiato";
      };
    };
  };
}
