{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my;
in {
  imports = [
    ./1password
    ./common-utilities
    ./disko
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
      gnome.enable = cfg.role == "desktop";
      _1password.enable = cfg.role == "desktop";
      sound.enable = cfg.role == "desktop";
      i18n.enable = true;
      nix.enable = true;
    };
  };
}
