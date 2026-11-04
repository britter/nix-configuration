# INWX

OpenTofu configuration for the INWX nameserver zones of all three domains
(`ritter.family`, `britter.dev`, `benediktritter.de`).

This module replaces `../cloudflare/` as part of the DNS migration
([plan](../../../docs/plans/cloudflare-to-inwx-dns-migration.md)). While the
domains still delegate to Cloudflare's nameservers, the zones created here are
inert — they only become authoritative once the NS delegation flips (phase 4).

Record conventions differ from Cloudflare:

- Apex records are created by omitting `name` (Cloudflare uses `"@"`).
  INWX rejects CNAMEs at the apex, so the Netlify apex records use INWX's
  `ALIAS` type instead of Cloudflare's CNAME flattening.
- Wildcards are spelled out in the name (`*`, `*.srv-prod-1`), same as in the
  INWX panel.
- TTLs are explicit (minimum 300). 300 mirrors Cloudflare's "Auto" TTL for
  DNS-only records.

The `britter.dev` / `benediktritter.de` web records were ported from the
`britter/domains` repository (which also manages the out-of-scope
`autoweird.fm` zone). That repo can be retired once the INWX zones are
authoritative.
