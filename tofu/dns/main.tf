locals {
  tailnet = "tail74798e.ts.net"
}

module "tailscale" {
  source  = "./tailscale"
  tailnet = local.tailnet
}

module "inwx" {
  source   = "./inwx"
  host_ips = module.tailscale.device_ips
}
