{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.dell-latitude-7280
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules
  ];

  my = {
    host = {
      name = "latitude-7280";
      system = "x86_64-linux";
      role = "desktop";
    };
    modules = {
      disko = {
        enable = true;
        disk = "/dev/sda";
        swapSize = "8GB";
      };
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.printing.enable = true;

  home-manager = {
    users.bene = {
      imports = [
        ../../home/latitude.nix
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
