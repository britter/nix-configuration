# This project's state bucket/credentials are fully manual; see README.

output "managed_state_user_credentials" {
  value = {
    for k, key in garage_key.state_users :
    k => {
      access_key = key.access_key_id
      secret_key = key.secret_access_key
    }
  }
  sensitive = true
}

output "restic_bucket_domain_names" {
  value = { for k, b in garage_bucket.restic_buckets : k => b.global_alias }
}

output "restic_user_credentials" {
  value = {
    for k, key in garage_key.restic_users :
    k => {
      access_key = key.access_key_id
      secret_key = key.secret_access_key
    }
  }
  sensitive = true
}

output "restic_restore_user_credentials" {
  value = {
    access_key = garage_key.restic_restore_user.access_key_id
    secret_key = garage_key.restic_restore_user.secret_access_key
  }
  sensitive = true
}

output "global_read_access_key" {
  value     = garage_key.global_read_user.access_key_id
  sensitive = true
}

output "global_read_secret_key" {
  value     = garage_key.global_read_user.secret_access_key
  sensitive = true
}
