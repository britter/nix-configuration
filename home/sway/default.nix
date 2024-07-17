{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.sway;
in {
  options.my.home.desktop.sway = {
    enable = lib.mkEnableOption "sway";
  };

  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
    };
    wayland.windowManager.sway = {
      enable = true;
      config = {
        terminal = "${pkgs.alacritty}/bin/alacritty";
        menu = "${lib.getExe config.programs.rofi.finalPackage} -show drun -show-icons -pid";
        bars = [{command = "${pkgs.waybar}/bin/waybar";}];
      };
    };
  };
}
