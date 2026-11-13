# Keycloak SSO rollout for all home lab services

**Status:** planning

Goal: every service behind `*.ritter.family` authenticates against the
Keycloak realm `homelab` (issuer `https://account.ritter.family/realms/homelab`),
following the established client pattern from the Forgejo and PVE
onboardings (see
[`docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md`](archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md)
and
[`docs/plans/archive/2026-10-30-proxmox-keycloak-sso.md`](archive/2026-10-30-proxmox-keycloak-sso.md)).

The service list below mirrors the directions homepage
(`modules/nixos/homepage.nix`) plus directions itself.

## Approach

- Make a small plan document per service to prepare onboarding.
- **Native OIDC** apps get a `keycloak_openid_client.<name>` resource in
  `tofu/keycloak/` (one file per client, per the existing convention)
  and are configured in the app itself.
- **Password login (decided 2026-11-12):** the end state is forced SSO —
  username/password login disabled — for every service where disabling
  is possible. Super-critical services are the exception and keep local
  login as break-glass; PVE keeps `root@pam` (disabling local login is
  not possible anyway). Name the exceptions and the break-glass in each
  onboarding plan, and disable passwords only after the first SSO login
  is verified (Beszel's staged pattern).
- **Automatic user creation (decided 2026-11-12):** the end goal is to
  auto-create accounts on first SSO login wherever the app supports it.
  Keep it off while a service's SSO is rolled out, enable it once that
  rollout is verified safe. Forgejo, PVE and Home Assistant already
  create users for unknown realm identities; Beszel has it off.
- **Auth proxy** apps (no OIDC support) are gated by a reverse-proxy
  layer in front of the app (e.g. `oauth2-proxy` wired to Keycloak), with
  one Keycloak confidential client per protected vhost. The app's own
  local login remains as break-glass.
- Think about how to enable Gatus service monitoring, e.g. is it possible
  to exclude the health endpoint from sso login?
- **Not possible** apps (UniFi admin UI, TrueNAS) stay on local auth;
  they are documented here only for completeness.
- Identify pre-existing users and decide on how to map them.
- Local admin credentials stay available as break-glass everywhere, even
  where password login is disabled (Beszel: the sops password plus the
  env flip; PVE: `root@pam`).
- Document required click-ops for setting up auth in `<root>/docs`.

## Service status

| Service | URL | OIDC out of the box? | State | Comment |
| --- | --- | --- | --- | --- |
| Keycloak | `account.ritter.family` | — (is the IdP) | ✅ Running | Realm `homelab`, tofu-managed |
| Forgejo | `git.ritter.family` | Native | ✅ Done | See archived plan (srv-prod-6) |
| Proxmox VE | `pve.ritter.family` | Native | ✅ Done | See archived plan; `root@pam` break-glass |
| Nextcloud | `nextcloud.ritter.family` | Native (user_oidc app) | ⏳ Pending | Disable local passwords after migration — plan: [`nextcloud-keycloak-sso.md`](nextcloud-keycloak-sso.md) |
| Stirling PDF | `pdf.ritter.family` | Native | ⏳ Pending | First attempt abandoned (2026-11-10): the full build with login/SSO is `mit unfree` and would rebuild from source on every nixpkgs churn with the current pull-based rollout — see [`../plans/stirling-pdf-keycloak-sso.md`](../plans/stirling-pdf-keycloak-sso.md) → Outcome and [`../ideas/self-hosted-binary-cache.md`](../ideas/self-hosted-binary-cache.md). Free build has no login code at all; without the cache work this stays auth-proxy-shaped (Calibre-Web style). |
| Vaultwarden | `passwords.ritter.family` | Native | ⏳ Pending | SSO is admin-toggleable; keep master password unlock working |
| Paperless-ngx | `documents.ritter.family` | Native | ⏳ Pending | django-allauth based; admin account needed for first login — plan: [`paperless-keycloak-sso.md`](paperless-keycloak-sso.md) |
| Immich | `photos.ritter.family` | Native | ⏳ Pending | |
| Calibre Web | `books.ritter.family` | Native OIDC in CWNG — blocked by the [CWNG migration](cwa-migration.md) | ⏳ Pending | Today's calibre-web has no OIDC. The CWNG target ships env-managed Generic OIDC (discovery URL, secret from file, `groups`-claim admin mapping) — the web UI becomes a Keycloak client: `bene` (realm `admins` group) as admin, everyone else auto-created with a default role. Device surfaces keep local credentials permanently: `/opds` (KOReader basic auth embedded in the URL), Kobo sync tokens, `/kosync` and the KOSync vhost — exempt from SSO/proxy (no browser redirect possible); the local login form stays because OPDS shares the same credential store. |
| Navidrome | `music.ritter.family` | No — auth proxy | ⏳ Pending | Subsonic clients don't follow browser SSO; proxy must allow API paths or stay read-only compromise |
| Home Assistant | `homeassistant.ritter.family` | No core OIDC — HACS [`hass-oidc-auth`](https://github.com/christiaangoossens/hass-oidc-auth) | ✅ Done | See [archived plan (2026-11-10)](archive/2026-11-10-homeassistant-keycloak-sso.md). Public client (PKCE S256, no secret); local password login stays (break-glass + companion-app provider); automatic user linking on until the second household account links once |
| IT Tools | `tools.ritter.family` | No auth at all — auth proxy | ⏳ Pending | Pure static app; proxy is the only gate |
| Homepage (directions) | `home.ritter.family` | No auth at all — auth proxy | ⏳ Pending | |
| Beszel | `beszel.ritter.family` | Native | ✅ Done | Password login disabled (`DISABLE_PASSWORD_AUTH`); see [archived plan (2026-11-09)](archive/2026-11-09-beszel-keycloak-sso.md) |
| Gatus | `status.ritter.family` | Native | ⏳ Pending | Keep unauthenticated uptime exposure in mind — SSO hides status from the household |
| AdGuard Home | `adguard.ritter.family` | No — auth proxy | ⏳ Pending | DNS query APIs (DoH/DoT) must bypass the proxy |
| UniFi Network | `unifi.ritter.family` | No | ❌ Not possible | Confirmed: UniFi admin UI has no OIDC support; local auth stays |
| TrueNAS | `truenas.ritter.family` | No | ❌ Not possible | Confirmed: no OIDC support; local auth stays |
| FritzBox | `fritz-box.ritter.family` | No — auth proxy | ⏳ Pending | Router admin behind proxy; keep LAN-side direct access as break-glass |

## Order of work

1. Stand up the shared auth proxy (choose one deployment, e.g.
   `oauth2-proxy` on srv-prod-1 next to Keycloak) and a Keycloak client
   for it; validate against a low-risk target first (IT Tools).
2. Onboard the native-OIDC Office/Media apps one client file at a time
   (Nextcloud, Paperless, Immich, Vaultwarden, Stirling PDF). Calibre
   Web joins this group only after the CWNG migration
   ([`cwa-migration.md`](cwa-migration.md)) lands — native OIDC does
   not exist in today's calibre-web.
3. Onboard remaining native apps (Gatus; Home Assistant and Beszel
   are done).
4. Gate the remaining proxy-only vhosts (Navidrome,
   AdGuard, Homepage, FritzBox).
5. Update `docs/homelab.md` and the directions homepage entries as each
   service lands; archive this plan when the table is fully ✅/❌.
