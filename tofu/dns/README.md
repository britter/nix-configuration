# External DNS configuration

External DNS records for all three domains are managed here with OpenTofu:

- `inwx/` — the authoritative setup since 2026-11-10: all three domains
  are registered at INWX and delegate to INWX's nameservers
  (the [Cloudflare-to-INWX migration](../../docs/plans/archive/2026-11-11-cloudflare-to-inwx-dns-migration.md)
  is complete except for phase 6).
- `cloudflare/` — removed 2026-11-11 (migration phase 6): the zones it
  managed were deleted from the Cloudflare account. The remaining Cloudflare
  resources (`autoweird.fm` in the `britter/domains` repo) live outside this
  tofu project.

DNS records point to [Tailscale](https://tailscale.com) IP addresses.
Tailscale provider is used to retrieved IP addresses of known devices from the Tailscale API.
Using that data DNS entries are automatically created via INWX.

The interplay between these public records and the local DNS overrides
(AdGuard Home) is described in [docs/split-dns.md](../../docs/split-dns.md).

The [INWX](https://inwx.de) provider uses the automation-account
credentials from `secrets.json`, keys `inwx_username` / `inwx_password`.

## Known issues

### Tailscale data refresh times out

This is because Tailscale API tokens are only valid for at most 90 days, so every once in a while the API token is invalided making all requests fail.
To fix this go to tailscale.com > Settings > Personal Settings > Keys and generate a new API token.
Put the new token in `./secrets.json`.
