# object-storage

Module for managing object storage on Garage, exposed at
`garage.srv-prod-3.ritter.family`.

Garage has no IAM policies: permissions are grants per key x bucket, and
keys cannot be scoped to prefixes. As a result, per-service restic backups
and per-project Tofu state are modelled as one bucket per service/project
in Garage.

## Layout

- `tofu-states-object-storage` — state bucket for this project
  (object-storage), **fully manual**: tofu never manages it or its key
- `tofu-states-<project>` + key `tofu-<project>` (rw) — state buckets/keys
  for other Tofu projects, managed
- `restic-<service>` + key `restic-<service>` (rw) — one bucket per service
  with restic backups
- key `restic-restore` (ro) — read access to all restic buckets for restores
- key `global-read` (ro) — read access to all buckets, for synchronizing
  content between instances during migrations

Credentials are provided via the top-level `secrets.json` (sops-encrypted):
the scoped Garage admin API bearer token under
`srv_prod_3_garage_admin_token`. All S3 credentials created by tofu are
exposed as outputs. Note that Garage only shows a key's secret once at
creation — after that, Terraform state is the record.

## State bucket

### State bucket (manual, permanently)

Tofu cannot create its own backend's bucket (chicken-and-egg), so the state
bucket and key for this project are bootstrapped manually and stay manual —
they are not imported into state, not managed, and not touched by tofu.
State buckets for other projects are managed resources.

One-time setup on srv-prod-3:

```bash
garage bucket create tofu-states-object-storage
garage key create tofu-state-object-storage
garage bucket allow --read --write --owner \
  --key tofu-state-object-storage tofu-states-object-storage
```

(The grant is needed — a new key has access to no bucket by default; the
state backend needs read, write, and owner since tofu manages the bucket's
contents.)

Then point the backend at `tofu-states-object-storage` with the manual key's
credentials. The `global-read` user does not have access to this bucket; state
bucket content is synced by hand (or via the admin token) during migrations.

### Migration between instances

See [MIGRATION.md](./MIGRATION.md) for the concrete rclone-based process. In
summary:

- Add Tofu configuration to set up the new instance
- Roll out the changes
- Synchronize the content from the old instance to the new one using rclone:
  the old instance's global read user reads, the new instance's per-bucket rw
  keys write (see [MIGRATION.md](./MIGRATION.md)). Per-service restic backups
  live in `restic-<service>` buckets, so sync each into its matching bucket
  on the new instance
- Verify everything is fine on the new instance (including restores)
- Update the top level `secrets.json` to contain the credentials for the new
  instance. Update all Tofu backend configurations to manage state on the new
  instance
- Verify everything is fine
- Decommission the old instance
