terraform {
  backend "s3" {
    bucket                      = "tofu-states"
    key                         = "home-lab/minio/terraform.tfstate"
    region                      = "eu-central-1"
    endpoint                    = "https://minio.srv-prod-3.ritter.family"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.18.0"
    }
  }
}

module "srv-prod-3" {
  source        = "./minio"
  endpoint      = "minio.srv-prod-3.ritter.family"
  root_user     = var.srv_prod_3_root_user
  root_password = var.srv_prod_3_root_password
}

module "srv-prod-3-new" {
  source        = "./minio"
  endpoint      = "minio.srv-prod-3-new.ritter.family"
  root_user     = var.srv_prod_3_new_root_user
  root_password = var.srv_prod_3_new_root_password
}

output "srv_prod_3_state_bucket_domain_name" {
  value = module.srv-prod-3.state_bucket_domain_name
}

output "srv_prod_3_state_user_credentials" {
  value     = module.srv-prod-3.state_user_credentials
  sensitive = true
}

output "srv_prod_3_restic_bucket_domain_name" {
  value = module.srv-prod-3.restic_bucket_domain_name
}

output "srv_prod_3_restic_user_credentials" {
  value     = module.srv-prod-3.restic_user_credentials
  sensitive = true
}

output "srv_prod_3_restic_restore_user_credentials" {
  value     = module.srv-prod-3.restic_restore_user_credentials
  sensitive = true
}

# User for syncing the entire contents to another minIO installation
output "srv_prod_3_global_read_user_access_key" {
  value     = module.srv-prod-3.global_read_access_key
  sensitive = true
}

output "srv_prod_3_global_read_user_secret_key" {
  value     = module.srv-prod-3.global_read_secret_key
  sensitive = true
}
