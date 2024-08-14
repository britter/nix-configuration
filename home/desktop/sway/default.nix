{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.sway;
in {
  imports = [
    ./mako.nix
    ./sway.nix
    ./swayidle.nix
    ./swaylock.nix
    ./waybar.nix
  ];
  options.my.home.desktop.sway = {
    enable = lib.mkEnableOption "sway";
  };
  config = lib.mkIf cfg.enable {
    # TODO extract programs specifically required to build a
    # desktop environment into dedicated submodule
    home.packages = with pkgs; [
      gnome.nautilus # file browser
      loupe # image provider
      wl-clipboard # terminal access to the clipboard
    ];
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
    };
    wayland.windowManager.sway = {
      enable = true;
    };
    my.home.desktop.sway = {
      mako.enable = true;
      swayidle.enable = true;
      swaylock.enable = true;
      waybar.enable = true;
    };
  };
}
