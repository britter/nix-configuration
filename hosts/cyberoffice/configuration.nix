{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules
    ../../modules/disko
  ];

  my = {
    host = {
      name = "cyberoffice";
      system = "x86_64-linux";
      role = "server";
    };
    user = {
      # default name baked into the ISO image
      name = "nixos";
      # TODO make this optional. Signing is not required on servers.
      signingKey = "394546A47BB40E12";
    };
    modules = {
      disko = {
        enable = true;
        disk = "/dev/sda";
      };
    };
  };

  # TODO extract into a VM module
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
  services.qemuGuest.enable = true;

  # TODO extract this into a module. Make IP address part of my.host
  networking = {
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.178.200";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.178.1";
    nameservers = ["192.168.178.105"];
    firewall = {
      allowedTCPPorts = [80 443];
    };
  };

  environment.etc."nextcloud-admin-pass".text = "test-installation-PWD";
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "localhost";
    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      extraTrustedDomains = ["192.168.178.200"];
    };
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
