# MBR based partitioning using ext filesystem for use in Proxmox VMS.
# By default Proxmox uses SeaBIOS to boot VMs and that required legacy
# boot using MBR.
# This is taken from https://github.com/nix-community/disko/blob/9d5c673a6611b7bf448dbfb0843c75b9cce9cf1f/example/gpt-bios-compat.nix
{
  device ? throw "Set this to your disk device, e.g. /dev/sda",
  storageDisk,
  lib,
  ...
}: {
  disko.devices = {
    disk.main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
            priority = 1; # Needs to be first partition
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
    disk.storage = lib.mkIf (storageDisk != null) {
      device = storageDisk;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          storage = {
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes = {
                "/var/lib" = {
                  mountpoint = "/var/lib";
                  mountOptions = ["noatime"];
                };
              };
            };
          };
        };
      };
    };
  };
}
