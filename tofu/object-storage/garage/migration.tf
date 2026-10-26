# Garage key for the minIO → Garage migration (see MIGRATION.md).
# Temporary: remove after the migration is complete.

resource "garage_key" "migration" {
  name = "migration"
}

resource "garage_bucket_key" "migration_state_rw" {
  for_each = garage_bucket.project_state_buckets

  bucket_id     = each.value.id
  access_key_id = garage_key.migration.access_key_id
  read          = true
  write         = true
  owner         = false
}

resource "garage_bucket_key" "migration_restic_rw" {
  for_each = garage_bucket.restic_buckets

  bucket_id     = each.value.id
  access_key_id = garage_key.migration.access_key_id
  read          = true
  write         = true
  owner         = false
}

output "migration_credentials" {
  value = {
    access_key = garage_key.migration.access_key_id
    secret_key = garage_key.migration.secret_access_key
  }
  sensitive = true
}
