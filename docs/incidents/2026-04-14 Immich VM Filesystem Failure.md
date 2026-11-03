## 🧩 Problem

The Immich service running inside VM `400` became unreachable. The application failed to start due to a database connection error. Logs indicated PostgreSQL failures caused by filesystem-level write errors.

Symptoms observed:

- Immich backend service would not start
- PostgreSQL reported inability to access database files
- VM root filesystem mounted in read-only mode (`emergency_ro`)
- Application-level failures despite other VMs functioning normally

---

## 🔍 Root Cause

The root cause was **ext4 filesystem corruption inside the VM root disk**, triggered by **underlying storage I/O errors at the Proxmox host layer**.

Key contributing factors:

### Primary cause

- Intermittent **I/O errors on the virtual disk device (`/dev/sda` inside VM)**

### Likely origin of I/O instability

- NVMe-backed Proxmox host storing LVM-thin VM disk
- Temporary storage disruption or latency spike at block layer

### Impact mechanism

1. Write I/O failures occurred on VM disk
2. ext4 journal was aborted mid-write
3. filesystem remounted as read-only (`emergency_ro`)
4. inode and directory structures became inconsistent
5. PostgreSQL inside Immich lost ability to read/write database files
6. Application failure cascade → Immich unreachable

### Contributing factor (non-failure)

- NFS/ZFS media storage remained unaffected (correct separation of storage tiers)
- Only VM root disk was impacted, confirming localized block-device issue

---

## Timeline / Logs

### Initial symptom

- Immich service became unreachable from network

---

### VM-level errors observed

- PostgreSQL failure during startup:
    - `could not open file "base/...": Read-only file system`
- Node.js backend crash due to DB connection failure

---

### Kernel-level filesystem errors inside VM

- EXT4 I/O errors during write operations:
    - `I/O error, dev sda`
    - `ext4_end_bio: I/O error writing to inode`
- Journal failure:
    - `Aborted journal on device sda2`
- Filesystem remount:
    - `EXT4-fs ... remounted read-only`

---

### Proxmox host investigation

- VM disk identified as:
    - `pve/vm-400-disk-0` (LVM-thin)
- Partition layout confirmed via GPT inside LV
- fsck initially failed due to missing partition mapping
- Loop device mapping used to expose filesystem:
    - `/dev/loop0p2`

---

### Recovery actions performed

- Forced partition exposure using loop device (`losetup -fP`)
- Full filesystem check:
    - `fsck.ext4 -f /dev/loop0p2`
- Extensive ext4 repair operations:
    - inode fixes
    - directory reconstruction
    - orphaned inode cleanup
    - block/inode bitmap correction
- Filesystem marked as modified and successfully repaired

---

## 🛠 Resolution Steps

### 1. Disk mapping recovery

- Used loop device to expose LVM-backed partition:

`losetup -fP /dev/pve/vm-400-disk-0`

---

### 2. Filesystem repair

- Ran forced filesystem check:

`fsck.ext4 -f /dev/loop0p2`

- Applied repairs:
    - directory structure rebuild
    - inode reference corrections
    - orphaned inode cleanup
    - metadata consistency restoration

---

### 3. Cleanup

- Detached loop device:

`losetup -d /dev/loop0`

---

### 4. Service recovery

- Started VM:

qm start 400

- Verified system state:
    - root filesystem mounted read-write
    - Immich service started successfully
    - database connectivity restored

---

## ✅ Outcome

- VM fully recovered without reinstallation
- ext4 filesystem restored to consistent state
- Immich service operational again
- No evidence of permanent data loss
- Media storage on NFS/ZFS remained unaffected throughout incident