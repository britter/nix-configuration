# Keycloak Terraform configuration

Manages the Keycloak realm `homelab` — including its SMTP configuration and
its users — and the OIDC clients of the services that use it for single
sign-on: one `keycloak_openid_client` resource per service.

The Keycloak server itself is deployed with NixOS on srv-prod-1, see
[nix-configuration](https://github.com/britter/nix-configuration): the
deployment plan is archived at
`docs/plans/archive/2026-10-29-keycloak-sso-on-srv-prod-1.md`, and the
first OIDC client (Forgejo) is onboarded per
`docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md`
(both complete). The second client is the PVE hypervisor
(`client-pve.tf`); its OIDC realm on the hypervisor is one-time `pveum`
state — runbook and quirks in
`docs/plans/archive/2026-10-30-proxmox-keycloak-sso.md`.

## Credentials

The provider authenticates with the `tofu` service-account client in the
`master` realm (client-credentials grant — the provider docs' recommended
setup). Its id and secret, the Keycloak URL, and the state bucket
credentials live in the sops-encrypted `secrets.json`; rules for it are in
[`tofu/.sops.yaml`](../.sops.yaml). Locally, enter this directory and
`direnv allow` — the `.envrc` decrypts the state bucket credentials and
loads the shared dev shell from the repository root flake.

## Realm and users

The realm is created by tofu. If it is ever created manually first, import
it before planning:

```
tofu import keycloak_realm.homelab homelab
```

Users created by tofu (`keycloak_user`) get no password from tofu — a
password in the tofu state would be a liability. Set passwords via the
admin console or the forgot-password mail.

## Restricting who can use a client (per-service gate)

By default, every enabled realm user can authenticate against every
*enabled* OIDC client — Keycloak has no implicit per-client user
allow-list. What vanilla Keycloak also lacks is any built-in way to
restrict *one given client* to specific users when the login itself
flows through it:

- Authorization Services policies/permissions (realm role + role policy
  + permission, `ENFORCING` mode) evaluate only RPT/UMA permission
  requests. A plain authorization-code login is never stopped by them,
  no matter what role the user does or does not carry — see the
  Authorization Services Guide and keycloak/keycloak discussion #20779
  for the scoping of these mechanisms.
- The known-good remedy is the third-party authenticator
  [`sventorben/keycloak-restrict-client-auth`](https://github.com/sventorben/keycloak-restrict-client-auth):
  deployed as a JAR in the Keycloak NixOS module (package override), it
  makes the browser flow deny logins unless a per-client policy (e.g.
  a realm role) permits the user. That is the future path when the
  realm grows and services must diverge — not deployed today.

Until then, the gate is each application's own authorization model,
with the realm's admin-provisioned userbase as the outer shell
(registration off, unique admin-set e-mails):

- **PVE** uses its native OIDC realm (issuer, client id and secret,
  autocreate) on top of its own ACL system: an
  auto-created SSO user starts with zero PVE privileges and stays there
  until an explicit `pveum acl modify`. There is nothing to build
  Keycloak-side for PVE — the ACL grant on the hypervisor is the gate.
- **Forgejo** gates via the deployment order its plan enforced: only
  activated e-mails exist to auto-link against
  (`ACCOUNT_LINKING = "auto"`), so a realm identity cannot spawn
  anything unexpected.

Role assignments to users are managed with `keycloak_user_roles`
(v5.10; `keycloak_user_realm_roles` exists only as a data source).
Roles *inside* an application are not a Keycloak concern: Keycloak only
delivers claims (realm roles, client roles, groups) and the mapping is
per app. The Forgejo auth source supports `--group-claim-name` /
`--admin-group` for claim-driven promotion; PVE does not consume
claims for authorization at all — its own users/ACLs are authoritative.

## Break-glass: lost admin access

```bash
ssh root@srv-prod-1.ritter.family
systemctl stop keycloak
# creates a NEW temporary admin; the db options must match the service
# (db "keycloak", user "keycloak" — see `systemctl cat keycloak` for the
# rendered config).
KC_DB=postgres KC_DB_USERNAME=keycloak KC_DB_PASSWORD='…' \
KC_BOOTSTRAP_ADMIN_USERNAME=temp-admin KC_BOOTSTRAP_ADMIN_PASSWORD='…' \
  kc.sh bootstrap-admin user
systemctl start keycloak
```

Then log in as `temp-admin`, restore access to the real admins (reset a
password / re-assign the `admin` role), delete `temp-admin`. `kc.sh` is on
the system PATH because the NixOS module adds the package to
`environment.systemPackages`.
