# Disko configuration for formatting the main disk, see https://github.com/nix-community/disko
# Most of this originates from https://www.youtube.com/watch?v=YPKwkWtK7l0
# and https://github.com/katexochen/nixos/blob/f931172d272faa2e15a08d757edf9a6072527d02/modules/disko/btrfs-luks.nix
{device ? throw "Set this to your disk device, e.g. /dev/sda", ...}: let
  btrfsMountOpts = ["compress=zstd" "noatime"];
in {
  disko.devices = {
    disk.main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["default"];
            };
          };
          swap = {
            size = "8G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              extraOpenArgs = ["--allow-discards"];
              askPassword = true;
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                askPassword = true;
                content = {
                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      mountOptions = btrfsMountOpts;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = btrfsMountOpts;
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = btrfsMountOpts;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
