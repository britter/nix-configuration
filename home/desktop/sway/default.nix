{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.desktop.sway;
in {
  imports = [
    ./kanshi.nix
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
      dconf
      evince # pdf viewer
      nautilus
      adwaita-icon-theme
      file-roller # archive manager
      gnome-calendar
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
      kanshi.enable = true;
      mako.enable = true;
      swayidle.enable = true;
      swaylock.enable = true;
      waybar.enable = true;
    };
  };
}
