terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.6.5"
    }
  }
}

module "srv-prod-3" {
  source        = "./srv-prod-3"
  endpoint      = "minio.srv-prod-3.ritter.family"
  root_user     = var.srv_prod_3_root_user
  root_password = var.srv_prod_3_root_password
}

output "srv_prod_3_state_bucket_domain_name" {
  value = module.srv-prod-3.state_bucket_domain_name
}
