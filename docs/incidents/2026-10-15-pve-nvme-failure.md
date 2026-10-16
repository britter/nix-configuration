# Incident: PVE main NVMe media errors — 2026-10-15

Rescue plan and incident record for the failing main NVMe (`/dev/nvme0n1`)
on the PVE hypervisor (media errors 130 → 133 over the last week, per
beszel). Technician replaced the device the next day; this document covers
the overnight data-securing operation and the recovery procedure.

**Ground rules (during data securing, before the disk was removed)**

- Never boot into PVE. Every write to the failing disk is a loss of
  lifespan/readability. All work happens from the NixOS live ISO.
- All mounts of the broken disk are read-only. For ext4 use `ro,noload`
  (skips journal replay — plain `ro` can still write).
- Do mounts of TrueNAS with the explicit `addr=` option — the live ISO lacks
  `mount.nfs`, and without it the mount fails with
  `fsconfig() failed: NFS mount program didn't pass remote address`.

---

## Part 1 — Securing data (night of 2026-10-15)

### 1. Mount the TrueNAS NFS share

```sh
sudo mkdir -p /mnt/truenas
sudo mount -t nfs -o addr=192.168.10.20,vers=4.2,proto=tcp \
  192.168.10.20:/mnt/default-pool/pve-backup /mnt/truenas
```

If it is already mounted: skip. Check with `mount | grep truenas` and
`df -h /mnt/truenas` (need free space ≥ sum of exported VM disks).

### 2. Activate LVM (including thin pool) and inventory the disk

PVE uses an LVM-thin pool (`pve/data`) for the VM disks. The live ISO needs
two extra steps to handle it:

```sh
# the kernel module is present but not loaded:
sudo modprobe dm_thin_pool

# plain activation; `vgchange -a y --readonly` is NOT valid and fails with
# "Operation prohibited while --readonly is set". Activation itself writes
# nothing on a consistent VG — read-only protection comes from the `ro,noload`
# mount and the read-only dd/ddrescue usage below.
sudo vgchange -a y

sudo lvs -a -o+data_percent,origin
```

A warning `thin_check: execvp failed ... Check is skipped` is harmless
(only the optional pre-activation consistency check is skipped).

Expect `pve-root`, `pve-swap`, the thin pool `data` (plus internal
`data_tdata`/`data_tmeta`) and the VM volumes — confirmed mapping:
**`vm-100…600-disk-*` = srv-prod-1…6** (vm-200 full at 100% and
overprovisioned, mapping 220G; vm-300 has two disks).

### 3. Rescue PVE configuration (≈ 1 GB, minutes)

`/etc/pve` is pmxcfs; its real content is `/var/lib/pve-cluster/config.db`
on `pve-root`.

```sh
sudo mkdir -p /mnt/pve-root /mnt/truenas/rescue-2026-10-15
sudo mount -o ro,noload /dev/pve/root /mnt/pve-root

# tar archives preserve ownership/permissions inside the archive regardless of
# NFS (NFS may drop them on loose copies). --numeric-owner stores UIDs/GIDs as
# numbers, independent of the live ISO's user database.
sudo tar -C /mnt/pve-root --numeric-owner -cf /mnt/truenas/rescue-2026-10-15/pve-cluster-config.tar var/lib/pve-cluster/config.db
sudo tar -C /mnt/pve-root --numeric-owner -cf /mnt/truenas/rescue-2026-10-15/pve-root-etc.tar etc/

sudo umount /mnt/pve-root
```

Verify: `sudo tar -tf /mnt/truenas/rescue-2026-10-15/pve-cluster-config.tar` lists
`var/lib/pve-cluster/config.db`, and
`ls -la /mnt/truenas/rescue-2026-10-15/` shows both archives. `config.db` should
be several hundred KB or more.

### 4. Export VM disks (compressed raw, most important first)

The full VM fleet on this NVMe and where their data lives:

| VM | LV | Size (Data%) | Services | Local (on NVMe) | On TrueNAS (NFS) |
|---|---|---|---|---|---|
| srv-prod-1 | vm-100 | 64G (35%) | tailscale, beszel hub | configs | — |
| srv-prod-2 | vm-200 | 64G (**100%, overprovisioned: maps 220G**) | Nextcloud, Paperless, Vaultwarden, Stirling-PDF, Calibre-Web, git-server | paperless docs, vaultwarden DB, all DBs | nextcloud media |
| srv-prod-3 | vm-300 (2 disks) | 200G (92%) + 200G (77%) | Garage, Minio | **restic repos, tofu states** | — |
| srv-prod-4 | vm-400 | 64G (69%) | Immich | immich DB, ML cache | photos |
| srv-prod-5 | vm-500 | 64G (52%) | Navidrome | DB | music library |
| srv-prod-6 | vm-600 | 64G (65%) | Forgejo, it-tools, github-runners | repos + DB | — |

Export order used: srv-prod-2 first (small critical win: vaultwarden DB,
paperless docs), then both garage disks, then the rest. VMID → hostname
mapping confirmed: **vm-100…600 = srv-prod-1…6.**

```sh
dd if=/dev/pve/vm-200-disk-0 bs=4M status=progress | zstd > s2.zst
dd if=/dev/pve/vm-300-disk-0 bs=4M status=progress | zstd > s3-0.zst
dd if=/dev/pve/vm-300-disk-1 bs=4M status=progress | zstd > s3-1.zst
dd if=/dev/pve/vm-600-disk-0 bs=4M status=progress | zstd > s6.zst
dd if=/dev/pve/vm-400-disk-0 bs=4M status=progress | zstd > s4.zst
dd if=/dev/pve/vm-500-disk-0 bs=4M status=progress | zstd > s5.zst
dd if=/dev/pve/vm-100-disk-0 bs=4M status=progress | zstd > s1.zst
```

(Short output names; run from `/mnt/truenas/rescue-2026-10-15` as root. If
desired, rename later: `mv s2.zst srv-prod-2-disk0.raw.zst` etc.)

**Result:** all seven exports completed 2026-10-15 with zero dd read errors.
Actual network turned out to be 1 GbE (~109 MB/s sustained, not the feared
100 Mbit) — the whole fleet (~545 GB allocated → 366 GiB compressed) copied
in under 1.5 h. dd's `status=progress` shows the *read* side and bursts well
above link speed (RAM buffering); the honest number is `ls -lh` growth per
minute on the NFS target.

### 5. Full-disk image — COMPLETE 2026-10-15

Network resolved to 1 GbE, so the full image was added to the plan.

```sh
# pass 1 (no scratch): copy the good stuff, skip bad areas fast
ddrescue -f -n -d /dev/nvme0n1 /mnt/truenas/pve-nvme.img /mnt/truenas/pve-nvme.map
# pass 2, ONLY if pass 1 summary reports error_count > 0:
ddrescue -f -d -r3 /dev/nvme0n1 /mnt/truenas/pve-nvme.img /mnt/truenas/pve-nvme.map
```

Status at ~70%: 0 bad sectors, 0 bad areas, 0 read errors, avg 109 MB/s.
The 133 SMART media-error events did not translate into unreadable sectors
(corrected by ECC or reallocated). Final summary decides whether pass 2 runs.

Note: a clean ddrescue exit proves every sector was *readable*, not that the
image is bit-perfect (silent corruption can't be ruled out) — it is the
safety net under the exports and offsite backups, not a replacement for them.

### 6. Verify exports

```sh
cd /mnt/truenas/rescue-2026-10-15
for f in s*.zst; do zstd -t $f && echo "$f archive OK"; done
sha256sum s*.zst *.tar > SHA256SUMS   # baseline for transfer verification during restore
```

`zstd -t` proves each archive is internally consistent (the compression/NFS
path); the sha256 list proves any future copy of these files is identical.

### 7. Manifest (completed 2026-10-15)

Finished artifacts:

| File | Size | Completed |
|---|---|---|
| `pve-cluster-config.tar` | 400 KB | ✅ 2026-10-15 |
| `pve-root-etc.tar` | 3.2 MB | ✅ 2026-10-15 |
| `s1.zst` | 0.62 GiB | ✅ 2026-10-15 |
| `s2.zst` | 17.58 GiB | ✅ 2026-10-15 |
| `s3-0.zst` | 157.29 GiB | ✅ 2026-10-15 |
| `s3-1.zst` | 148.18 GiB | ✅ 2026-10-15 |
| `s4.zst` | 14.82 GiB | ✅ 2026-10-15 |
| `s5.zst` | 15.47 GiB | ✅ 2026-10-15 |
| `s6.zst` | 12.31 GiB | ✅ 2026-10-15 |
| `pve-nvme.img` + `.map` | 1024 GB, 100% rescued | ✅ 2026-10-15 |

Byte-exact sizes (for sha256-verified manifests): s1=666513042,
s2=18875935723, s3-0=168893307938, s3-1=159109952141, s4=15910754579,
s5=16609514721, s6=13220181067. Total VM exports ≈ 366 GiB.

**ddrescue final result (pass 1):** 1024 GB rescued, 100.00%,
**0 bad sectors, 0 bad areas, 0 read errors**, avg 108 MB/s, elapsed
2 h 37 m. The entire disk was readable — the 133 SMART media-error events
had all been corrected (ECC) or reallocated. No pass 2 needed.

### 8. Before the technician arrived

```sh
sudo umount /mnt/truenas
sync
poweroff
```

The NVMe can be kept after replacement — it is the only remaining source for
anything the image/exports missed.

---

## Part 2 — Recovery (2026-10-16, after the NVMe replacement)

All artifacts live in `/mnt/default-pool/pve-backup/rescue-2026-10-15/` on
TrueNAS (`pve-cluster-config.tar`, `pve-root-etc.tar`, the `s*.zst` VM disk
exports, `pve-nvme.img` + `.map`). Re-mount that share on whatever machine is
doing the restore.

The replacement NVMe was confirmed to have the **exact same byte size** as
the original (1024209543168 bytes), so the primary restore path is writing
the ddrescue image back — everything (partition table, LVM, thin pool, VM
disks, PVE config, host keys) comes back in one operation. The manual
rebuild (reinstall + config restore + VM import) is the fallback.

### 1. Primary path: write the image back to the new NVMe

Boot the NixOS live ISO on the PVE host (old NVMe removed, so no duplicate
VG/UUID conflicts), then:

```sh
# confirm the target is the new disk and empty:
lsblk -b -n -o SIZE /dev/nvme0n1      # must equal 1024209543168

mount -t nfs -o addr=192.168.10.20,vers=4.2,proto=tcp \
  192.168.10.20:/mnt/default-pool/pve-backup /mnt/truenas

dd if=/mnt/truenas/pve-nvme.img of=/dev/nvme0n1 bs=4M status=progress
# ≈ 2.6 h at ~109 MB/s; must exit 0 with exactly 1024209543168 bytes written
```

Do **not** `vgscan`/`vgchange` while dd is running, and do not boot PVE until
the write completes.

Then reboot into PVE. Expected on first boot: ext4 journal replay on
`pve-root` (like any unclean shutdown), all VM definitions, storage and
networks present. Check `dmesg` for surprises, then continue with step 3.

### 2. Fallback path: reinstall + manual restore

Only if the image write-back fails or the restored system proves corrupt.
Also useful as reference if a future incident lacks a full-disk image.

**a. Reinstall Proxmox VE** on the new NVMe: same hostname, same IP, same
LVM naming (`pve/root`, `pve/swap`). Apply the latest updates.

**b. Restore PVE configuration:**

```sh
scp <pve-backup-mount>:/rescue-2026-10-15/pve-cluster-config.tar /root/
tar -C /root -xf /root/pve-cluster-config.tar          # → /root/var/lib/pve-cluster/config.db
systemctl stop pve-cluster pveproxy
mv /var/lib/pve-cluster/config.db /var/lib/pve-cluster/config.db.new
cp /root/var/lib/pve-cluster/config.db /var/lib/pve-cluster/config.db
chown root:root /var/lib/pve-cluster/config.db
systemctl start pve-cluster
```

All VMs, storage definitions (`storage.cfg`) and networks reappear. Restore
any needed files from the rescued `etc/` by hand (e.g. SSH host keys from
`etc/ssh/ssh_host_*`, network config from `etc/network/interfaces`).

**c. Import VM disks** — mapping table:

| File | VM | LV to recreate |
|---|---|---|
| `s1.zst` | srv-prod-1 (100) | `vm-100-disk-0` |
| `s2.zst` | srv-prod-2 (200) | `vm-200-disk-0` |
| `s3-0.zst` | srv-prod-3 (300) | `vm-300-disk-0` |
| `s3-1.zst` | srv-prod-3 (300) | `vm-300-disk-1` (second disk!) |
| `s4.zst` | srv-prod-4 (400) | `vm-400-disk-0` |
| `s5.zst` | srv-prod-5 (500) | `vm-500-disk-0` |
| `s6.zst` | srv-prod-6 (600) | `vm-600-disk-0` |

Per VM (example srv-prod-2 / ID 200; repeat for each VM and disk):

```sh
# stream the compressed export onto the new host's storage
zstdcat /mnt/pve-backup/rescue-2026-10-15/s2.zst > /var/lib/vz/vm-200-disk-0.raw

# VM definitions came back from config.db; attach the raw disk:
qm set 200 --scsi0 local:200/vm-200-disk-0.raw
# (or import onto an LVM-thin storage: qm importdisk 200 vm-200-disk-0.raw local-lvm)
```

For srv-prod-3, do this **twice** (disk-0 and disk-1), attaching as
`scsi0` and `scsi1`.

After importing each VM: start it, log in via console, verify the service
stack comes up. Crash-consistent exports mean first boots may run an fsck /
journal recovery — that is normal and expected.

Repeat for every exported VM (srv-prod-2 → 200, srv-prod-3 → 300 with two
disks, srv-prod-6 → 600, etc. — mapping table above).

### 3. Boot order matters

1. **srv-prod-3 (garage) first.** Its restic repositories are the fallback
   for everything else.
2. Verify restic access: run a `restic snapshots` against the garage repos.
3. **srv-prod-2** (nextcloud, paperless, vaultwarden, stirling-pdf,
   calibre-web, git-server) — databases first (postgres), then apps.
4. **srv-prod-6** (forgejo).
5. **srv-prod-4** (immich — photos are on TrueNAS, only the DB is local),
   **srv-prod-5** (navidrome), **srv-prod-1** (beszel/tailscale).

If a VM's data proves inconsistent (crash-consistent export), restore from
the restic repo on garage — that is exactly what it is for.

### 4. Last resort: pull data from the full-disk image

Only if a needed artifact is missing or corrupt and the image was *not*
restored wholesale. The image contains the entire old NVMe (partition table,
LVM, thin pool):

```sh
losetup -r -f --show /mnt/pve-backup/rescue-2026-10-15/pve-nvme.img  # → /dev/loopN
vgscan --mknodes && modprobe dm_thin_pool && vgchange -a y
lvs -a                                            # old pve VG appears
# read individual LVs read-only, e.g.:
dd if=/dev/pve/vm-300-disk-0 bs=4M conv=noerror,sync | zstd > /restore/vm-300-disk-0.raw
vgchange -a n pve && losetup -d /dev/loopN        # release when done
```

Do **not** let anything write to the image; keep `-r` on the loop device.

### 6. Verify

- `restic check` on the restored repos (at least a subset / `--read-data-subset`).
- Nextcloud: `occ` works, files accessible, login works.
- Paperless, vaultwarden (unlock + password check!), forgejo: login + one repo.
- gatus / beszel dashboards green again.

### 7. Follow-up (the week after the incident)

- **Topology fix:** keep at least one restic target that does not share a
  disk, PSU or enclosure with what it protects. Garage on srv-prod-3 sits on
  the PVE NVMe — add a second restic leg writing to TrueNAS directly and/or
  extend the offsite leg on srv-offsite-1 to cover everything irreplaceable.
- **Thin-pool hygiene:** vm-200 is 100% allocated and overprovisioned
  (64G mapping 220G) — run/enable `fstrim.timer` inside the VMs so deleted
  blocks return to the thin pool (`pve/data` was at 85.75% full).
- **Monitoring:** alert on NVMe media errors *and* thin-pool Data% (beszel
  already collects it — make thresholds page you).
- **Hardware:** spare NVMe on hand + tested replacement routine; optional
  10 GbE (but note the TrueNAS pool is 5-disk RAIDZ2 HDD — single-stream
  gain would be ~2×, parallel streams ~4–8×; an NVMe mirror pool on TrueNAS
  for hot/restic data may be the better spend).
- Decide whether to keep the raw exports as long-term backup or delete them
  once the rebuilt host has completed a verified restic cycle.
