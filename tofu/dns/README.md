# External DNS configuration

External DNS records for all three domains are managed here with OpenTofu:

- `cloudflare/` — the current, authoritative setup (Cloudflare nameservers).
- `inwx/` — the target setup (INWX nameservers), created for the
  [Cloudflare-to-INWX migration](../../docs/plans/cloudflare-to-inwx-dns-migration.md).
  While the domains still delegate to Cloudflare these zones are inert; the
  two modules run in parallel until the nameserver delegation flips, after
  which `cloudflare/` is decommissioned (migration phase 6).

DNS records point to [Tailscale](https://tailscale.com) IP addresses.
Tailscale provider is used to retrieved IP addresses of known devices from the Tailscale API.
Using that data DNS entries are automatically created via Cloudflare.

The interplay between these public records and the local DNS overrides
(AdGuard Home) is described in [docs/split-dns.md](../../docs/split-dns.md).

The [INWX](https://inwx.de) provider uses the automation-account
credentials from `secrets.json`, keys `inwx_username` / `inwx_password`.

## Known issues

### Tailscale data refresh times out

This is because Tailscale API tokens are only valid for at most 90 days, so every once in a while the API token is invalided making all requests fail.
To fix this go to tailscale.com > Settings > Personal Settings > Keys and generate a new API token.
Put the new token in `./secrets.json`.
