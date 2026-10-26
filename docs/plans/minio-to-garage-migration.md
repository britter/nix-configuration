# Migration plan: minIO → Garage

Status: nearly complete (2026-10-26) — steps 1–4 are done (the ✅ marks
below). Remaining: step 5 (merge so the pipeline deletes the `migration`
key + two sops cleanups, already done) and step 6 (delete the minIO data
on srv-prod-3 and shrink its root disk). The repo-side changes for step 5
are done.

Steps and commands for migrating Tofu state and restic backups from minIO
(`minio.srv-prod-3.ritter.family`) to Garage (`garage.srv-prod-3.ritter.family`).
Both run on srv-prod-3, so rclone runs locally on that host.

Prerequisites: the Garage setup in this repo is rolled out (buckets and keys
exist, see README), including the temporary `migration` key managed by tofu
(`garage/migration.tf`), whose credentials come from the
`migration_credentials` output. On srv-prod-3, `garage` is a wrapper that
already carries the RPC secret — run its commands directly.

## ✅ 1. rclone remotes on srv-prod-3

nixpkgs has no declarative rclone module, so the config is rendered from a
sops template — the same pattern as the offsite `minio-sync` module. Add to
srv-prod-3's configuration in nix-configuration:

- sops secrets for the migration key credentials (copy the values from the
  `migration_credentials` output into the srv-prod-3 secrets file)
- a sops template rendering the following `rclone.conf`:

```ini
[minio]
type = s3
provider = Minio
endpoint = https://minio.srv-prod-3.ritter.family
access_key_id = <global-read user credentials>
secret_access_key = ...

[garage]
type = s3
provider = Other
region = garage
endpoint = https://garage.srv-prod-3.ritter.family
access_key_id = <migration key credentials>
secret_access_key = ...
```

The minIO `global-read` user is the copy source (read-only suffices); the
temporary `migration` key writes into all *managed* garage buckets. For the
manual `tofu-states-object-storage` bucket, grant the migration key access
by hand once:

```bash
garage bucket allow --read --write --key <migration access key ID> tofu-states-object-storage
```

## ✅ 2. Tofu state: copy, verify, cutover

Project prefixes map to their state buckets:

```bash
for proj in object-storage dns network proxmox; do
  rclone copy "minio:tofu-states/home-lab/$proj" "garage:tofu-states-$proj"
done
```

Verify (server side; `--size-only` avoids re-hashing the world):

```bash
for proj in object-storage dns network proxmox; do
  rclone check --size-only "minio:tofu-states/home-lab/$proj" "garage:tofu-states-$proj"
done
```

Then cut over the backends: update all Tofu backend configurations to point
at the garage state buckets (`tofu-states-<project>`, and
`tofu-states-object-storage` for this project) and move the state backend
credentials from the root `secrets.json` into the per-project
`secrets.json` files (see
[State backend credentials](#state-backend-credentials) below). Run a final
`rclone copy` per prefix (delta only), re-run the check, then verify
client-side per project:

```bash
# forces the backend to be re-read with the new credentials
tofu init -reconfigure
tofu plan   # must succeed and show no unexpected changes
```

From here on, the state buckets are on garage; minIO still serves restic.

## ✅ 2a. State backend credentials

Today the root `secrets.json` holds one pair of minIO credentials
(`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`) for the single `tofu-states`
bucket, shared by all four projects. It is consumed in two places:

- locally: the root `.envrc` decrypts it and exports every key verbatim
- on CI: the self-hosted runners get `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`
  injected globally via the sops template `state-backend-secrets`
  (`modules/nixos/github-runners.nix` in nix-configuration) as an
  `EnvironmentFile`

With garage, each project has its own state bucket (`tofu-states-<project>`)
and its own key (`tofu-<project>`; object-storage uses the manual
`tofu-state-object-storage` key). One global credential no longer works —
each project must authenticate with its own key, scoped to its own bucket.
The credentials therefore move from the root `secrets.json` into the
per-project `secrets.json` files, which already hold each project's provider
secrets. Add to each project's `secrets.json`:

- `state_bucket_key_id` / `state_bucket_secret_key`: the credentials of
  `tofu-<project>` (from the garage tofu outputs; for object-storage, the
  manual `tofu-state-object-storage` key). Both consumers below map these
  onto `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, so nothing else in the
  file leaks into the environment.

After the migration, remove `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` from
the root `secrets.json`.

### ✅ Local: direnv

Keep the root `.envrc` as is (`use flake` plus the sops export of the root
`secrets.json`); once the root file holds no more state-backend credentials,
the export block there can simply go. Give each project its own `.envrc` so
direnv picks up the nearest one when working in a subdirectory:

```bash
use flake

if secrets=$(sops -d secrets.json 2>/dev/null); then
  export AWS_ACCESS_KEY_ID=$(echo "$secrets" | jq -r .state_bucket_key_id)
  export AWS_SECRET_ACCESS_KEY=$(echo "$secrets" | jq -r .state_bucket_secret_key)
else
  log_status "sops: cannot decrypt secrets.json on this host, skipping secret export"
fi
```

Same structure as the root `.envrc`, but exporting only the two state bucket
entries under their AWS names. The per-project file is picked up because
direnv resolves `secrets.json` relative to the `.envrc` location. direnv only
loads the closest `.envrc`, so a per-project file cleanly shadows the root
one (and brings its own `use flake`).

### ✅ CI: workflows

The reusable `_tofu.yaml` runs with `working-directory: ${{ inputs.working-directory }}`
and the runner already has `SOPS_AGE_KEY_FILE` in its environment. The global
runner-side `EnvironmentFile` can go away; instead add one step to
`_tofu.yaml` before `tofu init` that loads the per-project backend
credentials into `$GITHUB_ENV`:

```yaml
- name: Load backend credentials
  run: |
    creds=$(sops -d secrets.json | jq -r '"AWS_ACCESS_KEY_ID=\(.state_bucket_key_id)",
      "AWS_SECRET_ACCESS_KEY=\(.state_bucket_secret_key)"')
    # GITHUB_ENV vars are not masked automatically; mask them in logs explicitly.
    echo "$creds" | while IFS== read -r name value; do echo "::add-mask::$value"; done
    echo "$creds" >> "$GITHUB_ENV"
```

Because the step runs in the job's working directory, it automatically picks
up that project's `secrets.json` — no per-workflow changes needed beyond the
one shared step.

### ✅ CI: runner cleanup (nix-configuration)

In `modules/nixos/github-runners.nix`, once all projects are migrated:

- remove `sops.secrets."github-runners/aws-access-key-id"` and
  `".../aws-secret-access-key"`
- remove the `state-backend-secrets` sops template and its `EnvironmentFile`
  service override
- keep `SOPS_AGE_KEY_FILE` — the workflows need it to decrypt the per-project
  `secrets.json`

The two `github-runners/aws-*` entries in the host sops secrets can then be
deleted.

## ✅ 3. Restic backups: copy, verify, cutover

Each minIO prefix is a self-contained restic repo; copy each into its
matching bucket:

```bash
for svc in git nextcloud vaultwarden calibre forgejo paperless; do
  rclone copy "minio:restic-backups/$svc" "garage:restic-$svc" --transfers 8 --checkers 16
done
```

Verify (server side):

```bash
for svc in git nextcloud vaultwarden calibre forgejo paperless; do
  rclone check --size-only "minio:restic-backups/$svc" "garage:restic-$svc"
done
```

Then cut over:

1. Pause the restic backup jobs briefly.
2. Update the restic config in nix-configuration (srv-prod-2:
   `_restic-constants.nix` and the per-service `services/restic.nix`): new
   repository URL
   (`s3:https://garage.srv-prod-3.ritter.family/restic-<service>`), new
   per-service credentials from the `restic_user_credentials` output in the
   sops secrets, and a `region = garage` where the S3 client needs it.
3. Run a final `rclone copy` per service — it only transfers the delta
   written since the initial copy.
4. Re-run the check, unpause the backup jobs.
5. Verify client-side (see below).
6. ✅ Once everything is verified, decommission minIO: the tofu state was
   switched to Garage, then `tofu state rm 'module.srv-prod-3'` orphaned the
   minIO resources, and the `minio/` module, its outputs, and the minIO
   provider were removed (see the README). Shut down the minIO service on
   srv-prod-3 itself once nothing reads from it anymore.

Client-side verification (run per service on the host running the backup;
the NixOS restic module generates a `restic-<svc>` wrapper on the system
path that sources the sops-rendered credentials, so no manual env setup is
needed):

```bash
restic-<svc> check
restic-<svc> snapshots
# and, to prove end-to-end restore works (only for small repositories such as git):
restic-<svc> restore latest --target /tmp/restic-restore-test
```

## 4. srv-offsite-1

srv-offsite-1 is the offsite backup host: a nightly `rclone sync` copies the
full contents of the object store on srv-prod-3 (`object-storage-sync`
module, `modules/hosts/srv-offsite-1/services/object-storage-sync.nix` in
nix-configuration — renamed from `minio-sync.nix` during this migration).
It runs its own garage instance (set up via the shared `garage` module in
nix-configuration). Two credentials are involved:

- **Read side (srv-prod-3):** the existing `global-read` user — rclone reads
  from `garage.srv-prod-3.ritter.family`.
- **Write side (srv-offsite-1):** a global write user on the *offsite*
  garage, since the nightly sync writes the full mirror there.

### ✅ Create the global write user on srv-offsite-1

Run once on srv-offsite-1 (secret shown once — it goes into that host's
sops secrets file):

```bash
garage key create global-write

# Keys cannot create buckets by default; allow it so rclone can create
# the mirror buckets itself (the key becomes owner of the buckets it creates):
garage key allow --create-bucket global-write
```

No `bucket allow` grants and no bucket pre-creation are needed: every
bucket the key creates via S3 `CreateBucket` is owned by it, which implies
full read/write.

### ✅ Reconfigure (nix-configuration), phase 1: extend rclone config

In `modules/hosts/srv-offsite-1/services/minio-sync.nix`, *temporarily* add
the garage remotes next to the existing minIO ones (the minIO sync keeps
running until the fill and the switch below are done):

- sops secrets: `srv-prod-3/garage/access-key` + `secret-key` (the
  `global-read` user on srv-prod-3), `garage/access-key` + `secret-key`
  (the `global-write` user on srv-offsite-1).
- Extend the `rclone.conf` template with:
  - `[garage-prod]`: `provider = Other`, `region = garage`,
    `endpoint = https://garage.srv-prod-3.ritter.family`, global-read
    credentials.
  - `[garage-offsite]`: `provider = Other`, `region = garage`,
    `endpoint = https://garage.srv-offsite-1.ritter.family`, global-write
    credentials.

### ✅ One-time: fill the offsite garage

After the last minIO sync has brought the latest data into the offsite
store, fill the offsite garage from it. Both remotes are local to
srv-offsite-1, so nothing is transferred over the network:

```bash
for svc in git nextcloud vaultwarden calibre forgejo paperless; do
  rclone copy "srv-offsite-1:restic-backups/$svc" "garage-offsite:restic-$svc"
done
for proj in object-storage dns network proxmox; do
  rclone copy "srv-offsite-1:tofu-states/home-lab/$proj" "garage-offsite:tofu-states-$proj"
done
```

### ✅ Reconfigure (nix-configuration), phase 2: switch and clean up

In `modules/hosts/srv-offsite-1/services/object-storage-sync.nix` (then
still named `minio-sync.nix`) and the srv-offsite-1 `configuration.nix`:

- Repoint the existing remotes at the garage instances, keeping their names:
  - `[srv-prod-3]`: `provider = Other`, `region = garage`,
    `endpoint = https://garage.srv-prod-3.ritter.family`, global-read
    credentials.
  - `[srv-offsite-1]`: `provider = Other`, `region = garage`,
    `endpoint = https://garage.srv-offsite-1.ritter.family`, global-write
    credentials.
- Revert the sync command to its original form
  (`rclone sync srv-prod-3: srv-offsite-1:`) — it is unchanged; only the
  remote definitions underneath changed.
- Remove the temporary `[garage-prod]`/`[garage-offsite]` remotes added in
  phase 1.
- Remove the minIO service from srv-offsite-1 (the `minio` import in its
  `configuration.nix`) — its data is no longer needed once the garage mirror
  is verified. Optionally wipe its data directory first.

## ✅ 5. Remove the migration user

The `migration` key is a global write key and must not outlive the
migration. Nothing depends on it anymore: the final delta sync was done in
cutover step 3, and srv-offsite-1 never used it (it uses `global-read` on
srv-prod-3 and `global-write` on its own garage).

Done in this repo:

- ✅ `garage/migration.tf` deleted. The repo-side work is done; the key
  still exists on garage until the pipeline applies after the merge.
- ✅ The rclone config that consumed the migration credentials was already
  removed with the minIO decommissioning (step 3).

## ⏳ 6. srv-prod-3: remove minIO data, shrink the root disk

The minIO service was removed from the config (step 3.6), but its data is
still on the host. The module used plain `services.minio.enable`, so the
data lives in the NixOS default state directory `/var/lib/minio` on the
**root** disk (scsi0, 200G, ext4) — the reason root sits at ~92%.
Everything else (garage) is on the separate scsi1 disk mounted at
`/mnt/data`, so root can shrink to 64G:

1. Once nothing needs restoring from it, delete the data:
   `rm -rf /var/lib/minio` (and any minIO-related nginx logs if desired).
2. Shrink the root disk from 200G to 64G. ext4 cannot shrink online and the
   disko root partition is `size = "100%"`, so this needs the rescue ISO
   (still attached as `ide2`, and in the boot order):
   - Boot srv-prod-3 from the ISO, open a shell, and mount nothing.
   - `e2fsck -f /dev/sda2` (required before an offline shrink), then
     `resize2fs /dev/sda2 60G` — shrink the FS below the target first.
   - `parted /dev/sda resizepart 2 63G` — keep the partition below 64G so
     the host-side volume shrink has headroom (512M ESP + 63G < 64G).
   - On the Proxmox host, shrink the backing volume:
     `lvreduce --size 64G pve/vm-300-disk-0` (verify the LV name with
     `lvs` first). Shrinking the volume before the partition would destroy
     data — guest side first, always.
   - Back in the guest: `resize2fs /dev/sda2` to fill the smaller partition,
     detach the ISO, reboot from scsi0.
3. Update `tofu/proxmox/srv-prod-3.tf` to match: scsi0 `size = "200G"` →
   `"64G"`, and the stale `description = "VM running minIO"` → garage.
   ✅ The description fix is already in the repo (safe, metadata-only).
   The size edit should land together with the actual shrink so the config
   never claims a size the disk doesn't have. The pipeline's plan comment
   on the PR shows how the provider treats the size change (PVE resize is
   grow-only, so a shrink in tf may show drift rather than an actionable
   diff — the tf edit keeps the config in sync with reality either way).
4. No disko changes needed: the root partition is `size = "100%"`, so it
   follows the disk size automatically.
