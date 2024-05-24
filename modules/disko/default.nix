{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.modules.disko;
in {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.my.modules.disko = {
    enable = lib.mkEnableOption "disko";
    disk = lib.mkOption {
      type = lib.types.str;
      description = "Disk to install to";
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      description = "Size of the swap partition";
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices =
      (import ./btrfs-luks.nix {
        device = cfg.disk;
        swapSize = cfg.swapSize;
      })
      .disko
      .devices;

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
