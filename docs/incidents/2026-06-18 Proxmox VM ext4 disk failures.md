# Incident Report – VM Filesystem Corruption on Proxmox (NixOS-based VMs)

## Symptom

Multiple VMs became unbootable or dropped into emergency/recovery mode. Services (e.g. Immich, MinIO) became unreachable. Boot process showed errors such as:

- Failed to start File System Check on /dev/disk/by-partlabel/disk-main-root
- VM console stuck in recovery shell or failed boot entirely

No issues were observed on other VMs initially, suggesting a disk-level or filesystem-level problem isolated to specific virtual disks.

---

## Diagnosis

### VM disk configuration (Proxmox host)

qm config 300

scsi0: local-lvm:vm-300-disk-0,size=200G

---

### Physical mapping

lsblk

nvme0n1p3
└─pve-vm--300--disk--0 200G lvm

---

### NVMe errors (critical)

journalctl -k -b | grep -Ei 'nvme|I/O error|reset|timeout|abort'

nvme0n1: I/O Error (READ)
critical medium error, dev nvme0n1

---

smartctl -a /dev/nvme0

Media and Data Integrity Errors: 19
Error Information Log Entries: 19
Unrecovered Read Error

---

## Recovery Goal

Mount VM disk on Proxmox host and run filesystem repair externally (VM unbootable).

---

## Recovery Steps

### 1. Identify VM disk
lvdisplay | grep vm-300

vm-300-disk-0  pve Vwi-aotz-- 200G data

Purpose: locate VM logical volume in LVM thin pool.

---

### 2. Attach partition table via loop device
losetup -fP /dev/pve/vm-300-disk-0

Purpose: expose partitions inside LVM volume.

lsblk /dev/loop0

loop0p1 512M EFI
loop0p2 199G Linux filesystem

---

### 3. Filesystem check and repair
fsck.ext4 -f /dev/loop0p2

Purpose:
- runs ext4 consistency check
- repairs directory tree, inodes, and metadata

Result:
Filesystem was modified and repaired successfully.

---

### 4. Cleanup
losetup -d /dev/loop0

Purpose: detach loop device safely.

---

### 5. Start VM
qm start 300

VM boots successfully after repair.

---

## Root Cause

Physical NVMe degradation:
- Media and Data Integrity Errors
- Unrecovered read errors
- Corruption propagated into VM disks and filesystems

---

## Resolution

Filesystem repaired via host-level fsck after exposing disk with loop device.
VM restored to bootable state.

---

## Key Takeaway

Root cause is hardware-level NVMe instability, not VM configuration.
