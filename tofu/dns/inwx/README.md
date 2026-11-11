# INWX

OpenTofu configuration for the INWX nameserver zones of all three domains
(`ritter.family`, `britter.dev`, `benediktritter.de`).

This module replaced `../cloudflare/` as part of the DNS migration
([plan](../../../docs/plans/cloudflare-to-inwx-dns-migration.md)). Since
2026-11-10 all three domains delegate to INWX's nameservers (verified at
the registries), so the zones created here are the authoritative ones.
`../cloudflare/` remains only as rollback until the migration's phase 6
decommissioning.

Record conventions differ from Cloudflare (these follow the proven setup in
the `testlens` infrastructure repo):

- Record names are FQDNs (`www.britter.dev`, `mail._domainkey.ritter.family`);
  apex records use the zone name itself as `name` (Cloudflare uses `"@"`).
  INWX rejects CNAMEs at the apex, so the Netlify apex records use INWX's
  `ALIAS` type instead of Cloudflare's CNAME flattening.
- Wildcards are spelled out in the name (`*.ritter.family`,
  `*.srv-prod-1.ritter.family`).
- Every record takes its `domain` from the `inwx_nameserver.zone` resource —
  that reference also orders record creation after zone creation (records
  hitting the INWX API before their zone exists fail with 2303).
- TTLs come from `local.ttl` (300, the INWX minimum, mirroring Cloudflare's
  "Auto" TTL for DNS-only records).

The `britter.dev` / `benediktritter.de` web records were ported from the
`britter/domains` repository (which also manages the out-of-scope
`autoweird.fm` zone). That repo can be retired once the INWX zones are
authoritative.
