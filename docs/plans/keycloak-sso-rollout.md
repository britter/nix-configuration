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
- Discuss pros and cons of disabling username password login.
- **Auth proxy** apps (no OIDC support) are gated by a reverse-proxy
  layer in front of the app (e.g. `oauth2-proxy` wired to Keycloak), with
  one Keycloak confidential client per protected vhost. The app's own
  local login remains as break-glass.
- Think about how to enable Gatus service monitoring, e.g. is it possible
  to exclude the health endpoint from sso login?
- **Not possible** apps (UniFi admin UI, TrueNAS) stay on local auth;
  they are documented here only for completeness.
- Identify pre-existing users and decide on how to map them.
- Local admin accounts stay untouched everywhere as break-glass, same
  as `root@pam` for PVE.
- Document required click-ops for setting up auth in `<root>/docs`.

## Service status

| Service | URL | OIDC out of the box? | State | Comment |
| --- | --- | --- | --- | --- |
| Keycloak | `account.ritter.family` | — (is the IdP) | ✅ Running | Realm `homelab`, tofu-managed |
| Forgejo | `git.ritter.family` | Native | ✅ Done | See archived plan (srv-prod-6) |
| Proxmox VE | `pve.ritter.family` | Native | ✅ Done | See archived plan; `root@pam` break-glass |
| Nextcloud | `nextcloud.ritter.family` | Native (user_oidc app) | ⏳ Pending | Disable local passwords after migration |
| Stirling PDF | `pdf.ritter.family` | Native | ⏳ Pending | Plan prepared: [`stirling-pdf-keycloak-sso.md`](stirling-pdf-keycloak-sso.md) |
| Vaultwarden | `passwords.ritter.family` | Native | ⏳ Pending | SSO is admin-toggleable; keep master password unlock working |
| Paperless-ngx | `documents.ritter.family` | Native | ⏳ Pending | django-allauth based; admin account needed for first login |
| Immich | `photos.ritter.family` | Native | ⏳ Pending | |
| Calibre Web | `books.ritter.family` | No — auth proxy | ⏳ Pending | OPDS catalog at `/opds` is consumed by KOReader using basic-auth credentials embedded in the URL — the proxy must exempt `/opds` from SSO and keep basic auth working there (no browser redirect possible) |
| Navidrome | `music.ritter.family` | No — auth proxy | ⏳ Pending | Subsonic clients don't follow browser SSO; proxy must allow API paths or stay read-only compromise |
| Home Assistant | `homeassistant.ritter.family` | Native | ⏳ Pending | Needs a trusted-proxy setup so local logins stay possible |
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
   (Nextcloud, Paperless, Immich, Vaultwarden, Stirling PDF).
3. Onboard remaining native apps (Home Assistant, Beszel, Gatus).
4. Gate the remaining proxy-only vhosts (Calibre Web, Navidrome,
   AdGuard, Homepage, FritzBox).
5. Update `docs/homelab.md` and the directions homepage entries as each
   service lands; archive this plan when the table is fully ✅/❌.
