# Keycloak Terraform configuration

Manages the Keycloak realm `homelab` — including its SMTP configuration and
its users — and the OIDC clients of the services that use it for single
sign-on: one `keycloak_openid_client` resource per service.

The Keycloak server itself is deployed with NixOS on srv-prod-1, see
[nix-configuration](https://github.com/britter/nix-configuration): the
deployment plan is archived at
`docs/plans/archive/2026-10-29-keycloak-sso-on-srv-prod-1.md`, and the
first OIDC client (Forgejo) is onboarded per
`docs/plans/forgejo-keycloak-sso-on-srv-prod-6.md`.

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
*enabled* OIDC client — Keycloak has no implicit per-client
user allow-list. When a service must only be usable by specific people
(the PVE hypervisor, for example), build the gate in tofu:

1. One realm role per service, assigned only to the intended users:
   `keycloak_role`, then `keycloak_user_realm_roles` (or the group
   route — `keycloak_group` + `keycloak_group_memberships` +
   `keycloak_group_roles` — when several users share the grant).

2. Gate the client with fine-grained authorization: enable
   Authorization Services on the client
   (`keycloak_openid_client` gains `authorization_services_enabled` +
   `policy_enforcement_mode = "ENFORCING"`), define a role policy
   (`keycloak_openid_client_authorization_policy`) over the gate role,
   and attach it with
   `keycloak_openid_client_authorization_permission`. Users without the
   role are rejected by Keycloak at the authorization step — before the
   application ever sees them.

3. Keep the application's own authorization model as defense in depth.
   For PVE specifically: its native OIDC realm (issuer, client id and
   secret, autocreate) sits on top of PVE's own ACL system — an OIDC
   user gets no PVE privileges until PVE roles are granted there, so
   the Keycloak gate plus "grant nothing in PVE" double-locks the
   hypervisor. Lock both layers when onboarding PVE.

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
