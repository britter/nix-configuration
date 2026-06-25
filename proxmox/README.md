# Proxmox Terraform configuration

Terraform configurations for managing VMs in my Proxmox based home lab.

For machine provisioning see [nix-configuration](https://github.com/britter/nix-configuration).

## Useful commands

### Importing an existing VM

```
terraform import proxmox_vm_qemu.<resource name> pve/vm/<vmid>
```

### Recreating a VM

```
terraform taint proxmox_vm_qemu.<resource name>
```
