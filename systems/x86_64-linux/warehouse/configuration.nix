{...}: {
  imports = [
    ../../../modules/nixos
  ];

  my = {
    host = {
      name = "warehouse";
      system = "x86_64-linux";
      role = "server";
    };
    modules = {
      disko = {
        enable = true;
        bootDisk = "/dev/sda";
        storageDisk = {
          disk = "/dev/sdb";
          subvolumes = ["/var/lib/minio" "/var/lib/postgres"];
        };
      };
    };
  };

  # TODO extract into a VM module
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
  services.qemuGuest.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
