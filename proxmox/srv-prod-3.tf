resource "proxmox_vm_qemu" "srv_prod_3" {

  target_node = "pve"
  vmid        = "213"
  name        = "srv-prod-3"
  desc        = "Storage VM running minIO"
  tags        = "nixos;linux;production"

  onboot  = true
  agent   = 1
  cores   = 2
  sockets = 1
  cpu     = "host"
  memory  = 2048

  define_connection_info = false
  full_clone             = false
  scsihw                 = "virtio-scsi-single"
  boot                   = "order=scsi0;ide2;net0"
  vm_state               = "running"

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/nixos-minimal-25.11.20250905.8eb28ad-x86_64-linux.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage = "default-pool"
          size    = "64G"
        }
      }
      scsi1 {
        disk {
          storage = "default-pool"
          size    = "6T"
        }
      }
    }
  }
}
