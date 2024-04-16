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
    ./nix
    ./sound
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

      # enabled on all machines by default
      fonts.enable = true;
      i18n.enable = true;
      nix.enable = true;
    };
  };
}
