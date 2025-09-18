resource "minio_s3_bucket" "state_bucket" {
  bucket = "tofu-states"
}

resource "minio_s3_bucket_versioning" "state_versioning" {
  bucket = minio_s3_bucket.state_bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

output "state_bucket_domain_name" {
  value = minio_s3_bucket.state_bucket.bucket_domain_name
}

variable "tofu_projects" {
  type    = list(string)
  default = ["home-lab", "domains"]
}

module "state_users" {
  source   = "./modules/minio-user"
  for_each = toset(var.tofu_projects)

  username   = "tofu-${each.key}"
  bucket     = minio_s3_bucket.state_bucket.bucket
  prefix     = each.key
  permission = "rw"
}

output "state_user_credentials" {
  value = {
    for k, m in module.state_users :
    k => {
      access_key = m.access_key
      secret_key = m.secret_key
    }
  }
  sensitive = true
}
