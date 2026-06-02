_: {
  flake.modules.nixos.proxmox-vm = {
    boot.initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
    services.qemuGuest.enable = true;
  };
}
