resource "proxmox_vm_qemu" "srv_prod_4" {

  target_node = "pve"
  vmid        = "400"
  name        = "srv-prod-4"
  description = "VM for Immich server"
  tags        = "nixos;linux;production"

  cpu {
    cores   = 4
    sockets = 1
  }
  memory = 6144

  agent                  = 1
  define_connection_info = false
  full_clone             = false
  bios                   = "ovmf"
  scsihw                 = "virtio-scsi-single"
  boot                   = "order=scsi0;ide2;net0"

  power_state        = "running"
  start_at_node_boot = true
  startup_shutdown {
    order            = -1
    shutdown_timeout = -1
    startup_delay    = -1
  }

  network {
    id     = 0
    bridge = "vmbr1"
    model  = "virtio"
  }

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/nixos-minimal-26.05.20260123.c5296fd-x86_64-linux.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "64G"
        }
      }
    }
  }
}
