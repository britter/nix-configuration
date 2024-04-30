{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.tuxedo-pulse-14-gen3
    ./hardware-configuration.nix
    ../../modules
  ];

  my = {
    host = {
      name = "pulse-14";
      system = "x86_64-linux";
      role = "desktop";
      profiles = ["private"];
    };
    user.signingKey = "394546A47BB40E12";
    modules = {
      disko = {
        enable = true;
        disk = "/dev/nvme0n1";
        swapSize = "32GB";
      };
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.printing.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
