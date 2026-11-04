# Cloudflare

Terraform configuration for modifying Cloudflare DNS records.
Each server has a decidated file that creates a wildcard DNS record pointing at that server's local IP.

The ACME DNS-01 credential for `security.acme` is no longer managed here: it is a shared token stored in the sops file `modules/nixos/https-proxy/secrets.yaml` (key `cloudflare/api-token`), wired up by the `https-proxy` NixOS module. See [docs/plans/cloudflare-to-inwx-dns-migration.md](../../docs/plans/cloudflare-to-inwx-dns-migration.md).
