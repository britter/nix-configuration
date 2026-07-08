terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.38.3"
    }
  }
}

provider "minio" {
  minio_server   = var.endpoint
  minio_user     = var.root_user
  minio_password = var.root_password
  minio_region   = "eu-central-1"
  minio_ssl      = true
}
