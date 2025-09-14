locals {
  tailnet = "tail74798e.ts.net"
}

module "tailscale" {
  source  = "./tailscale"
  tailnet = local.tailnet
}

module "cloudflare" {
  source             = "./cloudflare"
  cloudflare_zone_id = var.cloudflare_zone_id
  host_ips           = module.tailscale.device_ips
}

output "acme_tokens" {
  value     = module.cloudflare.acme_tokens
  sensitive = true
}
