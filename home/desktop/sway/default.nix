{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.sway;
in {
  imports = [
    ./flameshot.nix
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
      cosmic-files
      evince # pdf viewer
      gnome.file-roller # archive manager
      gnome.gnome-calendar
      loupe # image provider
      qalculate-gtk # calculator
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
      flameshot.enable = true;
      mako.enable = true;
      swayidle.enable = true;
      swaylock.enable = true;
      waybar.enable = true;
    };
  };
}
