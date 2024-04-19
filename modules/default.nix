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
    ./common-utilities
    ./disko
    ./fonts
    ./gnome
    ./i18n
    ./my-user
    ./networking
    ./nix
    ./sound
    ./ssh-access
  ];
  options.my.host = {
    name = lib.mkOption {
      type = lib.types.str;
    };
    system = lib.mkOption {
      type = lib.types.enum inputs.flake-utils.lib.allSystems;
    };
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
      networking.enable = true;
    };
  };
}
