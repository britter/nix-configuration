resource "minio_s3_bucket" "restic_bucket" {
  bucket = "restic-backups"
}

output "restic_bucket_domain_name" {
  value = minio_s3_bucket.restic_bucket.bucket_domain_name
}

variable "restic_backups" {
  type = list(string)
  default = [
    "git",
    "nextcloud",
    "vaultwarden",
    "calibre",
    "forgejo",
    "paperless"
  ]
}

module "restic_users" {
  source   = "./modules/minio-user"
  for_each = toset(var.restic_backups)

  username   = "restic-${each.key}"
  bucket     = minio_s3_bucket.restic_bucket.bucket
  prefix     = each.key
  permission = "rw"
}

module "restic_restore_users" {
  source   = "./modules/minio-user"
  for_each = toset(var.restic_backups)

  username   = "restic-restore-${each.key}"
  bucket     = minio_s3_bucket.restic_bucket.bucket
  prefix     = each.key
  permission = "ro"
}

output "restic_user_credentials" {
  value = {
    for k, m in module.restic_users :
    k => {
      access_key = m.access_key
      secret_key = m.secret_key
    }
  }
  sensitive = true
}

output "restic_restore_user_credentials" {
  value = {
    for k, m in module.restic_restore_users :
    k => {
      access_key = m.access_key
      secret_key = m.secret_key
    }
  }
  sensitive = true
}
