{ inputs, config, ... }:
{
  flake.diskoConfigurations.srv-offsite-1 = {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices = {
      disk.main = {
        device = "/dev/nvme0n1"; # 256GB
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
      disk.storage = {
        device = "/dev/sda"; # 2TB
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
                    mountOptions = [ "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };

    boot.loader.grub.enable = true;
  };

  flake.modules.nixos.srv-offsite-1.imports = [
    config.flake.diskoConfigurations.srv-offsite-1
  ];
}
