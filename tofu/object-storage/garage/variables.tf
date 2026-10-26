variable "endpoint" {
  type        = string
  description = "Host:port of the Garage admin API"
}

variable "admin_token" {
  type        = string
  description = "Scoped Garage admin API bearer token"
  sensitive   = true
}

# Services with restic backups, mirrors the minIO module
variable "restic_backups" {
  type    = list(string)
  default = ["git", "nextcloud", "vaultwarden", "calibre", "forgejo", "paperless"]
}

# Tofu projects whose state buckets/keys are managed here. The state bucket
# for this project (home-lab) is created manually and imported, because tofu
# can't create the bucket its own backend uses.
variable "managed_tofu_projects" {
  type    = list(string)
  default = ["domains", "dns", "network", "proxmox"]
}
