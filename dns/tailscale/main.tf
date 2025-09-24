variable "tailnet" {
  type = string
}

locals {
  devices = [
    "srv-eval-1",
    "srv-test-1",
    "srv-test-2",
    "srv-prod-1",
    "srv-prod-2",
    "srv-prod-3",
    "srv-backup-1",
    "srv-offsite-1",
    "directions"
  ]
}
