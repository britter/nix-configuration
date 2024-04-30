{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.host;
in {
  imports = [
    ./1password
    ./adguard
    ./common/options
    ./common/utilities
    ./disko
    ./fonts
    ./gnome
    ./i18n
    ./my-user
    ./networking
    ./profiles
    ./nix
    ./sound
    ./ssh-access
  ];

  config = {
    my.modules = {
      # enabled only on desktops
      _1password.enable = cfg.role == "desktop";
      gnome.enable = cfg.role == "desktop";
      sound.enable = cfg.role == "desktop";

      # enabled only on servers
      ssh-access.enable = cfg.role == "server";

      # enabled on all machines by default
      fonts.enable = true;
      i18n.enable = true;
      networking.enable = true;
      profiles.enable = true;
    };
  };
}
