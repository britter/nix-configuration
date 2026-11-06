# Incident: untrusted certificates fleet-wide after switching to wildcard certs — 2026-11-06

After merging #349 (`https-proxy: request a single wildcard cert`), every
HTTPS name under `ritter.family` — LAN and tailnet — served a certificate
signed by an internal CA (`minica root ca *`) instead of the expected
Let's Encrypt certificate. Browsers flagged every homelab site as
untrusted; `beszel-agent` on directions logged
`tls: failed to verify certificate: x509: certificate signed by unknown
authority`.

## Timeline

| Time (CET) | Event |
|---|---|
| 09:43 | INWX DNS-01 issuance visibly working: `music.srv-prod-5.ritter.family` forced-renewed through INWX (per-vhost cert, #348) |
| 19:41 | #349 deployed fleet-wide (comin): one wildcard cert per host (`*.<host>.ritter.family`), plus `*.ritter.family` on directions |
| 19:41–19:48 | Every wildcard order fails at lego's DNS-01 propagation check; NixOS ACME falls back to self-signed `minica` certificates so dependent services still start |
| ~20:23 | Workaround deployed: `security.acme.defaults.dnsPropagationCheck = false` (2026-11-06, PR pending) |
| 20:39–20:42 | Retry attempts now fail *later* in the flow: lego passes the check, but Let's Encrypt rejects validation with `403 :: unauthorized :: No TXT record found at _acme-challenge.*` |

## Root cause

Two stacked issues, both introduced by the **cert-shape change in #349** —
not by the Cloudflare → INWX migration (the same zone layout with
Cloudflare would have behaved identically; the per-vhost renewal at
09:43 through INWX proves the provider path itself is fine).

### 1. Local: the UniFi gateway shadows the challenge names (fixed by the workaround)

lego verifies DNS-01 propagation by querying the *system* resolver,
which on every host is the home network's gateway (`192.168.30.1`, see
`docs/split-dns.md`). The gateway answers `ritter.family` names from its
local zone, which contains wildcard records defined at exactly the depth
the new challenge names occupy:

```
challenge:  _acme-challenge.srv-prod-2.ritter.family   ← one extra label
gateway:    *.srv-prod-2.ritter.family (A record)       ← matches!
```

With per-vhost certs (#348 and earlier), challenge names were two labels
deep (`_acme-challenge.music.srv-prod-5.ritter.family`) and never
matched a local wildcard, so the gateway forwarded to the public zone
and the check passed. With #349's wildcard names, the gateway serves its
own (TXT-less) answer and lego's check always times out. Disabling the
propagation check (`dnsPropagationCheck = false`) is correct here:
Let's Encrypt validates the TXT record through INWX's authoritative
nameservers itself.

### 2. Public: the zone's wildcard CNAME records capture the challenge nodes (open)

Disabling the local check exposed the second layer. The public zone
(INWX, and identically Cloudflare before) contains per-host wildcard
CNAME records used for tailnet-direct routing
(`*.srv-prod-N.ritter.family` CNAME → the host). DNS wildcards match
any *single* extra label — so these records also match the new
challenge names:

```
dig @ns.inwx.de _acme-challenge.directions.ritter.family CNAME
  → directions.ritter.family.   (synthesized by *.directions.ritter.family)
```

lego's solver follows the CNAME when solving (logged as
`dns01: Found CNAME entry … cname=directions.ritter.family.`) and
writes the challenge TXT **at the CNAME target** (`directions.ritter.family`
itself — the zone data confirms the TXT sits there, next to the apex A
record). Let's Encrypt then validates `_acme-challenge.<host>` by chasing
the same chain, and — depending on resolver cache state, which poisoned
itself with NODATA during the earlier failed attempts (inwx SOA minimum
TTL is 3600 s) — finds no TXT and rejects with 403. The window between
lego's present/cleanup dance and LE's validation makes this flakily
racy rather than simply wrong; the result is repeated 403s and the
trace loop continues.

## Resolution

Depends on the decision for #349's design; two options discussed:

1. **Structural fix in the zone data (preferred):** for each wildcard
   cert, publish an explicit CNAME at the challenge node pointing into a
   depth that no wildcard record can capture, e.g.

   ```
   _acme-challenge.srv-prod-2.ritter.family  CNAME  acme.<deep>.srv-prod-2.ritter.family
   ```

   with the target two-or-more labels below `<host>`. Explicit records
   override wildcard synthesis, so the challenge node stops being
   shadowed, resolution is identical for authoritative and recursive
   paths, and lego/LE both behave deterministically. Requires records in
   `tofu/dns/inwx/` and the same records in `tofu/dns/cloudflare/` until
   that zone is decommissioned (Phase 6).
2. **Fallback (lower-tech):** revert #349 fleet-wide (back to per-vhost
   certificates, which demonstrably renewed fine through INWX at 09:43)
   and re-introduce wildcard certs later with option 1's zone changes.

## Follow-ups

- `tofu/dns/` zone layout: challenge-node delegation records (option 1)
  or per-vhost enumeration (option 2 fallback).
- Keep `dnsPropagationCheck = false` permanently — with split DNS via
  the UniFi gateway, this local check can never succeed for wildcard
  names and is redundant (LE validates independently).
- The identical `minica root ca` fallbacks on every host (and the
  `beszel-agent` x509 warnings) are symptoms; they self-heal once orders
  succeed.
- Allocation of the event's flakiness: NODATA negative caching (inwx SOA
  min TTL 3600 s) can mask a *successful* TXT placement for up to an
  hour for any resolver that queried the apex TXT node before lego
  wrote it. Worth keeping in mind for future DNS-01 debugging under
  split DNS.
- `srv-offsite-1.ritter.family` resolves to directions' LAN IP
  (`192.168.30.6`) in the local zone; SSH'ing there lands on directions,
  not srv-offsite-1. Either the local record (tofu `unifi_dns_record`)
  or the intent needs a look — separate from this incident but noticed
  while debugging it.
