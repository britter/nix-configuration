{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my;
in {
  imports = [
    ./1password
    ./adguard
    ./common-utilities
    ./disko
    ./fonts
    ./gnome
    ./i18n
    ./my-user
    ./nix
    ./sound
    ./ssh-access
  ];
  options.my = {
    role = lib.mkOption {
      type = lib.types.enum ["desktop" "server"];
      description = "The role this machine has";
    };
  };

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
      nix.enable = true;
    };
  };
}
