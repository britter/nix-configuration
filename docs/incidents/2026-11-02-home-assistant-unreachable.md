# Incident: Home Assistant unreachable through the reverse proxy — 2026-11-02

Home Assistant at `homeassistant.ritter.family` rejected every request
routed through the reverse proxy on `directions` with `400: Bad Request`.
The web frontend still *rendered* (browser service-worker cache), but all
API/WebSocket calls behind it failed, showing the frontend's
"Unable to connect to Home Assistant. Retrying in … seconds" banner.
Discovered on 2026-11-02 while adding the first gatus endpoint check for
Home Assistant — the check immediately went red.

---

## Symptoms

- Browser: HA frontend loads, then "Unable to connect to Home Assistant.
  Retrying in 33 seconds…" — the service worker serves cached frontend
  assets, so the page looks half-alive. A misleading failure mode.
- Android app (new Pixel 10, no cached state): login impossible — the
  app's initial connection goes through the proxy and hits the same 400,
  and unlike the browser it has no cached frontend to render first.
- Every request via `https://homeassistant.ritter.family` returned a
  plain-text `400: Bad Request` for all paths, including `/`.
- Direct requests to `http://192.168.20.234:8123` worked fine
  (`/` → 200, `/api/` → 401, i.e. auth-required but healthy).

## Diagnosis

nginx on `directions` replaces the upstream `Server` header with its own,
so the 400 looked like it came from the proxy. It did not:

```sh
# direct, no proxy headers — healthy:
curl -i http://192.168.20.234:8123/api/          # → 401: Unauthorized

# direct, but with the header nginx adds — reproduced:
curl -i -H "X-Forwarded-For: 192.168.30.6" \
  http://192.168.20.234:8123/api/                # → 400: Bad Request
```

That plain-text `400: Bad Request` is Home Assistant's own response when
`http.use_x_forwarded_for` is set and the request carries
`X-Forwarded-For` from a proxy that is **not** in `http.trusted_proxies`.
The proxy side was correct (`proxyWebsockets = true` and
`recommendedProxySettings` in
`modules/hosts/directions/services/https-proxy.nix`).

## Root cause

The proxy-trust setting *effective* in Home Assistant held the proxy's
**old** IP. Details worth recording, because this failure mode is
unusually well-hidden:

- HA 2026.8 (2026-08) migrated the `http:` block out of
  `configuration.yaml` into UI storage (`/config/.storage/http`),
  importing the YAML **once** on first boot and ignoring the block
  thereafter. The import captured the pre-migration value —
  `trusted_proxies: 192.168.5.6`, the old *Homelab*-VLAN proxy IP.
- `directions` originally lived in the *Homelab* VLAN
  (192.168.5.0/24) with fixed IP `192.168.5.6` — the IP the trust
  setting was first configured for.
- `2eee4d9` (2026-04-09) introduced the *Servers* VLAN
  (192.168.30.0/24).
- `52e1ef9` + `2b073d5` (PR #70, 2026-10-25) moved `directions` into
  that VLAN: fixed IP `192.168.5.6` → `192.168.30.6`.
- `35b581f` (PR #71, later the same day) decommissioned the Homelab
  VLAN entirely, erasing the network the trusted entry pointed at.
- HA's *active* trust config (in `.storage/http`) kept `192.168.5.6` —
  a subnet that no longer existed — while proxy traffic arrived from
  the untrusted `192.168.30.6`. Every proxied request got a 400.
- Because the setting is UI-stored and the YAML block is dead, **no
  `configuration.yaml` change could have fixed this** — the config
  lived exclusively out of tree, invisible to this repo. The breakage
  went unnoticed for eight days because Home Assistant had no external
  uptime check until the gatus endpoint was added on 2026-11-02 (the
  same day this incident was discovered).

## Red herring: the firewall

While investigating, direct access to `http://192.168.20.234:8123` from a
browser appeared to time out, suggesting a missing firewall rule. It was
not:

- The existing UniFi policy `trusted_to_home_assistant`
  (`tofu/network/firewall_policies.tf`) already allows Trusted → port
  8123, and curl confirmed direct reachability from a Trusted-network
  host.
- The timeout happened because the browser dialed port 80 or 443 (URL
  typed without `:8123`, and/or HTTPS-First mode upgrading the scheme).
  The fix was simply using the explicit URL
  `http://192.168.20.234:8123`.

No firewall change was made.

## Resolution

*Corrected 2026-11-03: the fix described below was **not** applied via
`configuration.yaml`. HA 2026.8 (2026-08) migrated the entire `http:`
block into the UI and stores it in `/config/.storage/http`; the YAML
block is imported once and never read again. The working value lives in
UI storage; the `configuration.yaml` edit was a no-op.*

The actual fix, done in the HA UI on the device:

- **Settings > System > Network > HTTP server → Reverse proxy:**
  enable **Trust X-Forwarded-For**, add `192.168.30.6` to **Trusted
  proxies**, save and restart.
- HA then shows a confirmation dialog that must be confirmed **within
  5 minutes**, otherwise it reverts to the previous settings and
  restarts again.

The proxied URL and the gatus check went green afterwards.

The stale `http:` block in `configuration.yaml` (still showing
`trusted_proxies: 192.168.5.6`) is dead weight: HA raises a repair
("HTTP YAML configuration is ignored after migration") and will stop
tolerating it in 2027.2.0. It must be removed; nothing on the device
reads it.

## Follow-ups

- **Done:** `tofu/network/clients.tf` now carries a comment on
  `unifi_client.directions`: if its `fixed_ip` changes, Home Assistant's
  `http.trusted_proxies` must be updated out of tree, or HA rejects all
  proxied traffic with 400 again.
- **Remove the dead `http:` block** from the device's
  `configuration.yaml` before upgrading past 2027.2.0 (HA raises the
  "ignored after migration" repair until then). It is not read at all;
  nothing is lost by deleting it. *Decision 2026-11-03: that file is a
  few default includes, so managing it in git was evaluated and
  rejected — click-ops plus the guardrails above stay. Analysis:
  `docs/plans/archive/2026-11-03-home-assistant-config-git.md`.*
- **Monitoring:** this outage was only caught because the HA gatus check
  was added the same day. The service-worker behavior means HA can look
  fine in a browser tab while being broken — an external uptime check is
  the only reliable signal.
