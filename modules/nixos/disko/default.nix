{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.my.modules.disko;
  inherit (config.my.host) role;
in {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.my.modules.disko = {
    enable = lib.mkEnableOption "disko";
    bootDisk = lib.mkOption {
      type = lib.types.str;
      description = "Disk to install to";
    };
    swapSize = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Size of the swap partition";
      default = null;
    };
    storageDisk = {
      disk = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Disk to use for storage";
        default = null;
      };
      subvolumes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Mount points of the storage disk subvolumes";
        default = [];
      };
    };
  };

  config = let
    efi = cfg.enable && role == "desktop";
    mbr = cfg.enable && role == "server";
  in
    lib.mkMerge [
      (lib.mkIf efi {
        disko.devices =
          (import ./btrfs-luks.nix {
            device = cfg.bootDisk;
            inherit (cfg) swapSize;
          })
          .disko
          .devices;

        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
      })
      (lib.mkIf mbr {
        disko.devices =
          (import ./ext-mbr.nix {
            device = cfg.bootDisk;
            storageDisk = {
              inherit (cfg.storageDisk) disk;
              inherit (cfg.storageDisk) subvolumes;
            };
            inherit lib;
          })
          .disko
          .devices;

        boot.loader.grub = {
          enable = true;
        };
      })
    ];
}
