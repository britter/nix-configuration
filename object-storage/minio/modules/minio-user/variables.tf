variable "username" {
  description = "The name of the MinIO user"
  type        = string
}

variable "bucket" {
  description = "The bucket this user has access to"
  type        = string
}

variable "prefix" {
  description = "The prefix inside the bucket this user has access to"
  type        = string
}

variable "permission" {
  description = "Permission type for the user: rw or ro"
  type        = string
  default     = "rw"
  validation {
    condition     = contains(["rw", "ro"], var.permission)
    error_message = "Permission must be either 'rw' or 'ro'."
  }
}
