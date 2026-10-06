# Garage has no IAM policies; permissions are grants per key x bucket.

# This project's state bucket and key (tofu-states-object-storage) are fully
# manual — tofu never touches them.
# Managed state keys for the other tofu projects:
resource "garage_key" "state_users" {
  for_each = toset(var.managed_tofu_projects)
  name     = "tofu-${each.key}"
}

resource "garage_key" "restic_users" {
  for_each = toset(var.restic_backups)
  name     = "restic-${each.key}"
}

resource "garage_key" "restic_restore_user" {
  name = "restic-restore"
}

resource "garage_key" "global_read_user" {
  name = "global-read"
}

# Per-project state keys: rw+owner on their own bucket
resource "garage_bucket_key" "state_users_rw" {
  for_each = garage_bucket.project_state_buckets

  bucket_id     = each.value.id
  access_key_id = garage_key.state_users[each.key].access_key_id
  read          = true
  write         = true
  owner         = true
}

# Per-service rw keys
resource "garage_bucket_key" "restic_users_rw" {
  for_each = garage_bucket.restic_buckets

  bucket_id     = each.value.id
  access_key_id = garage_key.restic_users[each.key].access_key_id
  read          = true
  write         = true
  owner         = true
}

# Restore key: read-only across all service buckets
resource "garage_bucket_key" "restic_restore_ro" {
  for_each = garage_bucket.restic_buckets

  bucket_id     = each.value.id
  access_key_id = garage_key.restic_restore_user.access_key_id
  read          = true
  write         = false
  owner         = false
}

# Global read user: read-only on all managed buckets (migration syncs).
# Grant it access to the manual state bucket by hand if needed.
resource "garage_bucket_key" "global_read_restic_ro" {
  for_each = garage_bucket.restic_buckets

  bucket_id     = each.value.id
  access_key_id = garage_key.global_read_user.access_key_id
  read          = true
  write         = false
  owner         = false
}

