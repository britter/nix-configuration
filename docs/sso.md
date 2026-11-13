# SSO

Single sign-on for the homelab is provided by Keycloak on srv-prod-1,
realm `homelab`, issuer `https://account.ritter.family/realms/homelab`.
The realm and every OIDC client are tofu-managed in `tofu/keycloak/`
(one file per client); the realm has registration off and its users
(`bene`, `alina`) are admin-provisioned, so the userbase is effectively
an allow-list. All clients are standard-flow only with direct access
grants off and PKCE `S256` enforced, and SSO logins work via the public
FQDN only (other origins send a redirect URI that Keycloak rejects).

This document describes the current state per service. Services whose
onboarding is still pending are tracked in
[`plans/keycloak-sso-rollout.md`](plans/keycloak-sso-rollout.md) and not
listed here. The end state tracked there is forced SSO — password login
disabled and users auto-created on first login — for every service where
that is possible; super-critical services like PVE keep local login as
break-glass.

## Services with SSO enabled

| Service | URL | SSO mode | Password login | Auto-create users | User mapping | Role/permission mapping | Admin account |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Forgejo | [`git.ritter.family`](https://git.ritter.family) | Native OIDC (confidential client, PKCE S256) | Enabled. Also the only path for git-over-HTTPS and the API, which never route through SSO. | Yes (`ENABLE_AUTO_REGISTRATION`): unknown realm users get an active, non-admin account. | By verified e-mail (`ACCOUNT_LINKING = auto`); `preferred_username` becomes the username of auto-created accounts. | None. Access control stays Forgejo-side; auto-created users are non-admin. | Keycloak `bene` links by e-mail onto the local admin `britter` (created declaratively in the service `preStart`). `britter` is the admin; no dedicated admin account. |
| Proxmox VE | [`pve.ritter.family`](https://pve.ritter.family) | Native OIDC (confidential client, PKCE S256); PVE realm `keycloak` is one-time `pveum` state | Enabled. `root@pam` is untouched and is the break-glass. | Yes (`autocreate 1`); auto-created users have zero privileges. | By username claim: Keycloak `preferred_username` becomes `<username>@keycloak` (realm-scoped). | PVE ACLs. Auto-created users can do nothing until `pveum acl modify`; `bene@keycloak` holds Administrator on `/`. | `bene@keycloak` (Administrator on `/`, granted explicitly after the first login). `root@pam` remains the local break-glass. |
| Beszel | [`beszel.ritter.family`](https://beszel.ritter.family) | Native OIDC via PocketBase OAuth2 (confidential client, PKCE S256) | Disabled (`DISABLE_PASSWORD_AUTH=true` in the hub env). SSO is the only door; break-glass is removing that env line, which restores the sops-stored admin password on restart. | No (`USER_CREATION` off). | By e-mail: Keycloak `bene` links into the hub admin account created from `USER_EMAIL`. | None. Single-user hub; per-user system assignment stays Beszel-side. | The one hub admin account is the SSO account (e-mail link). The sops `beszel/hub-admin-password` is kept only as break-glass. |
| Home Assistant | [`homeassistant.ritter.family`](https://homeassistant.ritter.family) | OIDC via the HACS component `hass-oidc-auth` (public client, PKCE S256, no client secret) | Enabled. Break-glass, and the companion apps' refresh tokens depend on the built-in `homeassistant` auth provider. | Yes: unknown realm users get a fresh, unprivileged HA user. | Automatic user linking on exact username match (`preferred_username`); kept on deliberately until the second household user has linked once. | None. New users are non-admin; admin status stays HA-side. | The local admin user `bene` has the SSO identity linked onto it; its local password remains as break-glass. |
| Paperless-ngx | [`documents.ritter.family`](https://documents.ritter.family) | Native OIDC via django-allauth (confidential client, PKCE S256); configured entirely through env vars — the provider block with the client secret lives in a sops template | Disabled (`PAPERLESS_DISABLE_REGULAR_LOGIN=true`), which removes only the frontend password form. Break-glass: the Django admin at `/admin/` keeps accepting local credentials (upstream guarantee); removing the env line restores the form on the next switch. | Yes (default-on `SOCIALACCOUNT_ALLOW_SIGNUPS`): unknown realm users get an unprivileged account after a confirmation form (`SOCIALACCOUNT_AUTO_SIGNUP` stays off). | No e-mail auto-linking: an account connects its SSO identity itself via *My Profile → connect social account*. Keycloak `bene` is linked onto the dedicated local `bene` account that way; `alina` self-creates on her first login. | None. Auto-created users are non-admin; superuser status stays paperless-side. | Two local accounts: the superuser `admin` (sops `paperless/admin-password`) is local-only and never touches SSO — it remains the `/admin/` break-glass; the daily-driver `bene` holds the Keycloak identity. |

## Services without SSO

These have no OIDC support; they stay on local auth and are tracked as
"not possible" in the rollout plan:

| Service | URL | Reason |
| --- | --- | --- |
| UniFi Network (gateway) | [`unifi.ritter.family`](https://unifi.ritter.family) | The UniFi admin UI has no OIDC support. |
| TrueNAS | [`truenas.ritter.family`](https://truenas.ritter.family) | No OIDC support. |

## Where things are configured

- **Keycloak side** (realm, users, all clients): `tofu/keycloak/`,
  applied by the `OpenTofu Keycloak` pipeline. Client secrets are
  operator-generated in `tofu/keycloak/secrets.json`.
- **App side**: Forgejo's auth source and `oauth2_client` settings are
  declared in `modules/nixos/forgejo.nix`; Beszel's password switch is
  the hub env in `modules/nixos/beszel-hub.nix`; Paperless-ngx's SSO
  wiring (allauth env vars, provider block in a sops template) is in
  `modules/nixos/paperless.nix`; Home Assistant and the
  PVE realm are device-local state, documented as manual setup in
  [`homelab.md`](homelab.md).
- **Rollout history**: the archived plans under
  `docs/plans/archive/` (Forgejo 2026-10-29, Proxmox 2026-10-30,
  Beszel 2026-11-09, Home Assistant 2026-11-10,
  Paperless-ngx 2026-11-13).
