# Disko configuration for formatting the main disk, see https://github.com/nix-community/disko
# Most of this originates from https://www.youtube.com/watch?v=YPKwkWtK7l0
# and https://github.com/katexochen/nixos/blob/f931172d272faa2e15a08d757edf9a6072527d02/modules/disko/btrfs-luks.nix
{device ? throw "Set this to your disk device, e.g. /dev/sda", ...}: {
  disko.devices = {
    disk.main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["defaults"];
            };
          };
          swap-luks = {
            size = "32G";
            content = {
              type = "luks";
              name = "swap-crypted";
              extraOpenArgs = ["--allow-discards"];
              askPassword = true;
              content = {
                type = "swap";
                resumeDevice = true;
              };
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
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["noatime"];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["noatime"];
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = ["noatime"];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["noatime"];
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
