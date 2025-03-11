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

output "directions_acme_token" {
  value     = module.cloudflare.directions_acme_token_value
  sensitive = true
}

output "srv_eval_1_acme_token" {
  value     = module.cloudflare.srv_eval_1_acme_token_value
  sensitive = true
}

output "srv_test_1_acme_token" {
  value     = module.cloudflare.srv_test_1_acme_token_value
  sensitive = true
}

output "srv_test_2_acme_token" {
  value     = module.cloudflare.srv_test_2_acme_token_value
  sensitive = true
}

output "srv_prod_1_acme_token" {
  value     = module.cloudflare.srv_prod_1_acme_token_value
  sensitive = true
}

output "srv_prod_2_acme_token" {
  value     = module.cloudflare.srv_prod_2_acme_token_value
  sensitive = true
}
