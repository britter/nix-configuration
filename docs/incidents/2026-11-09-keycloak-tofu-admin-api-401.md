# Incident: tofu Keycloak provider fails with 401 on `/admin/serverinfo` — 2026-11-09

**Status:** resolved 2026-11-09 — the `kc-admin-api` scope was assigned
to the `tofu` client via the admin console; `tofu apply` works again.

`tofu plan` in `tofu/keycloak` fails during provider init:

```
Error: error initializing keycloak provider
failed to perform initial login to Keycloak: error sending GET request to
/admin/serverinfo: 401 Unauthorized. Response body: {"error":"HTTP 401 Unauthorized"}
```

Web UI (admin console and realm logins) kept working, so the server looked
healthy. The same 401 appeared in the `OpenTofu Keycloak` CI pipeline
(run for PR #356 at 08:47 UTC).

## Root cause

A Keycloak server upgrade, not a credential or IAM problem.

The renovate lock file maintenance PR
[#353](https://github.com/britter/nix-configuration/pull/353) (merged
2026-11-09 07:39 UTC) bumped nixpkgs-unstable from Keycloak **26.8.1 to
26.8.2**. After srv-prod-1 was rebuilt with that lock, every Admin REST
API call made with the `tofu` service-account token returned 401.

Keycloak 26.8.2 introduced the **Admin REST API audience check**
(RFC 9700; listed as a breaking change in the 26.8.2 upgrading notes):
the Admin API now only accepts bearer tokens that carry the built-in
`kc-admin-api` client scope and the matching `aud` claim. The upgrade
creates that scope in every realm and assigns it as a default scope to
the built-in clients (`admin-cli`, `security-admin-console`) — but **not
to custom service-account clients**. The `tofu` client (created by
click-ops per the archived rollout plan, section 1.5) therefore still
authenticates fine — the token request succeeds — but the resulting
token is rejected on the first Admin API call, which is the provider's
initial `GET /admin/serverinfo`.

This is easy to misread as a permissions problem because the roles on
the service account did not change and nothing needs to change: the
token is merely issued for the wrong audience. The admin console keeps
working because it runs as `security-admin-console`, which got the scope.

Timeline (UTC, 2026-11-09):

- 02:29 — last successful `tofu` CI plan (renovate lock maintenance, pre-bump)
- 07:39 — PR #353 merges the nixpkgs bump (Keycloak 26.8.1 → 26.8.2)
- morning — srv-prod-1 rebuilt with the new lock
- 08:46 — first failing `tofu` CI run with the 401 (beszel SSO PR #356);
  local `tofu plan` fails the same way

## Verification

Decode a token from the failing client and compare it with one from
`admin-cli`; the `tofu` token will lack `kc-admin-api` in `scope` and the
`/admin/realms/master` entry in `aud`:

```bash
echo "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {scope, aud}'
```

Also confirm the server version on the server info page of the admin
console (should be 26.8.2).

## Resolution

*Resolved 2026-11-09: the scope was assigned via the admin console as
described below, and `tofu apply` succeeded again. The standing
configuration is documented as required click-ops in
[`tofu/keycloak/README.md`](../../tofu/keycloak/README.md).*

Assign the `kc-admin-api` scope to the `tofu` client in the `master`
realm. This cannot be done via tofu (tofu is what is broken); use the
admin console, which still works:

1. Log in to `https://account.ritter.family` as an admin user.
2. Switch to the `master` realm → **Clients** → `tofu`.
3. **Client scopes** tab → **Add client scope** → select `kc-admin-api`
   → add as **Default**.

Then re-run `tofu plan` — the next token will carry the scope and the
audience. No role changes are needed, and cached tokens that predate the
scope assignment stay broken until re-issued (the provider re-logins per
run, so this only affects the first run after the fix).

CLI alternative (from srv-prod-1, using an `admin-cli` token, which has
the scope after the upgrade):

```bash
KC=https://account.ritter.family
TOKEN=$(curl -s -d grant_type=password -d client_id=admin-cli \
  --data-urlencode username="$KC_ADMIN_USER" --data-urlencode password="$KC_ADMIN_PASSWORD" \
  "$KC/realms/master/protocol/openid-connect/token" | jq -r .access_token)
CID=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "$KC/admin/realms/master/clients?clientId=tofu" | jq -r '.[0].id')
SID=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "$KC/admin/realms/master/client-scopes" | jq -r '.[] | select(.name=="kc-admin-api") | .id')
curl -fsS -X PUT -H "Authorization: Bearer $TOKEN" \
  "$KC/admin/realms/master/clients/$CID/default-client-scopes/$SID"
```

An escape hatch exists (`--spi-admin--audience-check-enabled=false` on
the server) but is strongly discouraged — it removes the RFC 9700
audience defense for the whole server.

## Follow-ups

- Bump `keycloak_version` in `tofu/keycloak/provider.tf` to `"26.8.2"`
  so it stays in sync with nixpkgs (the comment says renovate bumps
  both, but PR #353 only touched `flake.lock` — check the renovate
  config covers that attribute).
- Any future automation client that talks to the Admin API (e.g. the
  planned auth-proxy client work from the SSO rollout plan) needs
  `kc-admin-api` as a default scope right after creation — documented
  as required click-ops in [`tofu/keycloak/README.md`](../../tofu/keycloak/README.md).
- PR #356 (beszel onboarding) is blocked on this fix; rebase/re-run its
  pipeline after applying.
- Unrelated: the 07:31 CI run failed earlier at provider *installation*
  (`could not query provider` against the registry) — transient registry
  flakiness, distinct from this incident.
