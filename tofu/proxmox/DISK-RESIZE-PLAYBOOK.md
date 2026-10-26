# Disk Resize Playbook

Lessons from resizing srv-prod-2 (250G → 64G) and srv-prod-3 (200G → 400G).

## Golden rules

1. **Grow is easy, shrink is surgery.** ext4 can grow online (mounted, no
   downtime). Shrinking requires an unmounted filesystem — boot the
   nixos-minimal ISO that is attached as `ide2` on every VM.
2. **Shrink order: filesystem → partition → LV. Never reverse.** Cutting the
   LV below the partition corrupts the filesystem and destroys the GPT backup
   header. Recovering from that costs many more ISO rounds than doing it in
   the right order.
3. **parted uses decimal MB (10^6), not GiB.** 64 GiB = 68719.5 "MB" in
   parted units. This mismatch caused two near-corruptions. Prefer `sgdisk`
   with explicit sector numbers for anything precision-critical.
4. **Never change a partition's start sector.** The start maps the data. Only
   the end may move. Delete + recreate a partition with the same start sector
   is safe; a different start unmaps everything.
5. **The tofu provider cannot shrink a disk in place.** A planned in-place
   shrink (250G → 64G) actually created a new empty disk and attached it,
   leaving the VM unbootable. Never let tofu do a shrink. Shrink the LV by
   hand and update tf afterwards.

## Growing a disk (e.g. 200G → 400G)

1. Edit `size` in `proxmox/<vm>.tf` and `tofu apply`. Proxmox grows the
   volume online; the provider handles this correctly.
2. Inside the VM (no downtime, no ISO needed):

   ```bash
   sudo growpart /dev/sda 3        # partition holding the root fs/PV
   sudo pvresize /dev/sda3         # if LVM
   sudo lvextend -l +100%FREE /dev/vg/root
   sudo resize2fs /dev/vg/root     # online, safe
   # plain partition, no LVM: growpart then resize2fs
   ```

3. `df -h /` to verify.

## Shrinking a disk (e.g. 250G → 64G)

### 0. Verify the target size fits

```bash
df -B1 /          # used bytes must be well under the target
```

Leave headroom: the fs must end up smaller than the partition, and the
partition smaller than the disk minus ESP and GPT overhead.

### 1. Boot the ISO

- Flip boot order in tf: `boot = "order=ide2;scsi0;net0"`, apply, reboot.
  (Or `qm set <vmid> --boot order=ide2,scsi0,net0` on pve and sync tf later.)
- Work in the ISO console as root.

### 2. Shrink in the correct order (on pve + in ISO)

```bash
# In ISO — filesystem first, smaller than the target partition:
e2fsck -f /dev/sda2
resize2fs /dev/sda2 62G           # smaller than intended final fs

# Then partition — end on a 2048-sector boundary, inside the new disk size.
# With sgdisk (precise, preferred):
sgdisk -p /dev/sda                # note p2 START sector
sgdisk -d 2 /dev/sda
sgdisk -n 2:<START>:<END_SECTOR> -c 2:<partlabel> -t 2:8300 /dev/sda
sgdisk -e /dev/sda                # move backup GPT to the CURRENT disk end
sgdisk --verify /dev/sda          # must say "No problems found"

# Or parted, knowing its MB units are decimal:
parted /dev/sda resizepart 2 <END_MB>

# Grow the fs back to exactly fill the partition:
resize2fs /dev/sda2
e2fsck -f /dev/sda2
mount /dev/sda2 /mnt && ls /mnt && umount /mnt
```

Do `sgdisk -e` LAST, on the final (small) disk size — see pitfalls below.

### 3. Shrink the LV (on pve)

```bash
qm stop <vmid> && qm wait <vmid>
lvreduce -L 64G pve/vm-<vmid>-disk-0
qm start <vmid>
```

### 4. Reconcile VM config and tf

`lvreduce` does not update the VM config — the recorded `size=` is stale.
The stale `size` breaks kernel partition-table validation at boot
("start job is running for /dev/disk/by-partlabel/...") and confuses tofu.

```bash
# On pve — only after lvreduce:
qm set <vmid> --scsi0 local-lvm:vm-<vmid>-disk-0,discard=on,ssd=1,size=64G
qm config <vmid>    # verify size=64G

# In tf: size matches, and declare ssd/discard/replicate (emulatessd in tf).
# Then: tofu plan   → must show no changes. Import if it still wants to resize:
# tofu import proxmox_vm_qemu.<name> pve/qemu/<vmid>
```

### 5. Final checks (in VM)

```bash
lsblk                 # sda = new size
df -h /               # new fs size
sudo sgdisk --verify /dev/sda   # clean
sudo fstrim -av       # return freed space to the thin pool
```

## Pitfalls learned

- **Stale GPT header after lvreduce.** The GPT headers store "disk size /
  last usable sector". After shrinking the LV, the main header still claims
  the old size and the backup header sits past the new end. The kernel
  rejects the whole table → no partitions → boot hang. Fix: boot ISO,
  `sgdisk -e /dev/sda && sgdisk --verify`, `partprobe`. This is why
  `sgdisk -e` must be the last GPT operation, after any disk-size change.
- **Recreating a partition is safe.** `sgdisk -d`/`-n` only rewrites the
  table entry, never the data — as long as the start sector is unchanged.
- **`e2fsck` must run on the partition** (`/dev/sda2`), not the disk.
- **parted MB ≠ MiB.** Compute in sectors (sgdisk) or accept slack.
- **Thin volume stale mapping.** `lvs` warns "maps X while the size is only
  Y" after thin-LV shrink. Deactivate/reactivate doesn't clear it; it's
  cosmetic — the device presents the correct size. Only a volume recreate
  (lvcreate + dd + swap) clears it; not worth it.
- **Provider shrink creates a new disk.** If tofu plans an "in-place" size
  *reduction*, the provider may still destroy+create. Never shrink via tofu.
- **`qm set --boot` format** is `--boot order=scsi0,ide2,net0` (no `boot=`
  key), and the tf equivalent is `boot = "order=scsi0;ide2;net0"`
  (semicolons).
- **Provider attribute names**: `ssd` in qm is `emulatessd` in tf;
  `replicate` defaults to true in Proxmox but must be declared in tf or the
  provider will try to remove it.
- **Always finish with `fstrim -av`** in the VM after shrinking, or the thin
  pool never reclaims the freed space.

## Current state

| VM | disk | root fs |
|----|------|---------|
| srv-prod-1/4/5/6 | 64G | 64G |
| srv-prod-2 | 64G (shrunk from 250G) | ~63.4 GiB (62G shown by df) |
| srv-prod-3 | 200G | 200G — planned growth to 400G (partition layout has LVM root) |
