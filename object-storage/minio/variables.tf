variable "endpoint" {
  type        = string
  description = "URL to the MinIO server"
}

variable "root_user" {
  type        = string
  description = "Root user for MinIO"
  sensitive   = true
}

variable "root_password" {
  type        = string
  description = "Root password for MinIO"
  sensitive   = true
}
