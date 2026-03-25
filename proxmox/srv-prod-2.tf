resource "proxmox_vm_qemu" "srv_prod_2" {

  target_node = "pve"
  vmid        = "212"
  name        = "srv-prod-2"
  desc        = "VM running office related services"
  tags        = "nixos;linux;production"

  onboot  = true
  agent   = 1
  cores   = 2
  sockets = 1
  cpu     = "host"
  memory  = 4096

  define_connection_info = false
  full_clone             = false
  scsihw                 = "virtio-scsi-single"
  boot                   = "order=scsi0;ide2;net0"
  vm_state               = "stopped"

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/nixos-24.05.20240615.752c634-x86_64-linux.iso"
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
