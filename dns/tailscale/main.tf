variable "tailnet" {
  type = string
}

locals {
  devices = [
    "srv-prod-2",
    "srv-prod-3",
    "srv-prod-4",
    "srv-prod-5",
    "srv-offsite-1",
    "directions"
  ]
}
