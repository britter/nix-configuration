{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.proxmox-vm;
in {
  options.my.modules.proxmox-vm = {
    enable = lib.mkEnableOption "proxmox-vm";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
    services.qemuGuest.enable = true;
  };
}
