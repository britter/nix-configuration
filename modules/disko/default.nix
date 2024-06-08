{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.my.modules.disko;
  role = config.my.host.role;
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
      type = lib.types.nullOr lib.types.str;
      description = "Size of the swap partition";
      default = null;
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
            device = cfg.disk;
            swapSize = cfg.swapSize;
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
            device = cfg.disk;
          })
          .disko
          .devices;

        boot.loader.grub = {
          enable = true;
        };
      })
    ];
}
