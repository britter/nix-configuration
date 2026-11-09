# Beszel hub: Keycloak SSO (third native client)

**Status:** in progress — tofu client applied, Part B click-ops done
(OAuth / Keycloak OIDC provider ✅, Brevo SMTP ✅), first SSO login verified
✅ 2026-11-09; Part C (`DISABLE_PASSWORD_AUTH` + `APP_URL` in the hub
env, [`modules/nixos/beszel-hub.nix`](../../modules/nixos/beszel-hub.nix))
is on main awaiting the next comin switch / merge — the verification
step below closes this plan. Part of
[`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) (step 3, "remaining
native apps"); client conventions follow the Forgejo and PVE onboardings
([archive](archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md),
[archive](archive/2026-10-30-proxmox-keycloak-sso.md)). Status marks: ✅
done, ⏳ pending.

## Background

The hub runs on directions behind `https://beszel.ritter.family` (the
hub aspect's own vhost `beszel.directions.ritter.family` is a spare, see
the archived hub-move plan). Beszel's hub is PocketBase-backed: users
live in the `users` collection, and OAuth2/OIDC is a PocketBase feature
configured on that collection — Keycloak is a listed, known-working
custom OIDC provider. The callback path is fixed:
`/api/oauth2-redirect`, so the only redirect URI in play is
`https://beszel.ritter.family/api/oauth2-redirect` (PocketBase derives
it from the request origin — same caveat as PVE: logins must be opened
at the public FQDN; the spare vhost would generate a redirect URI that
Keycloak's check rejects).

What SSO does **not** touch:

- **Agents** connect to the hub with their own SSH-key/token handshake
  (`beszel-agent.nix`, `HUB_URL` + per-host `beszel/token`); they never
  authenticate against the `users` collection.
- **Gatus** monitors `https://beszel.ritter.family/api/health`, a public
  PocketBase endpoint that stays unauthenticated — service monitoring
  keeps working after SSO and even after password login is disabled.

## Chosen approach

The Keycloak side is tofu-managed like every client: one file per
client (`tofu/keycloak/client-beszel.tf`), confidential client,
authorization-code flow with PKCE S256 enforced (PocketBase's provider
config has a "Support PKCE" checkbox and only implements S256 — tick
it, or the login fails Keycloak's code-challenge requirement). The
client secret is operator-generated and seeded into
`tofu/keycloak/secrets.json` (`beszel_client_secret`), mirroring the
Forgejo/PVE pattern: the sops entry is the source of truth, and the
hub's copy is pasted once into the PocketBase UI (PocketBase stores
provider config in its own database; there is no env-var path for it —
this is the PVE situation, not the Forgejo one).

**User mapping:** there is exactly one pre-existing user — the hub
admin (`systemConstants.adminEmail`, `beneritter@gmail.com`), created
from `USER_EMAIL`/`USER_PASSWORD` env — and the realm's `bene` user
carries the same verified e-mail. PocketBase links an OAuth identity
into an existing user record by e-mail, so the first SSO login lands
in the existing admin account, systems/alerts intact. No `USER_CREATION`
(the Beszel default is off; the realm is single-person and
admin-provisioned, so there is nothing for auto-creation to do).

**Password login stays enabled in stage 1 and is disabled declaratively
in stage 3** via `DISABLE_PASSWORD_AUTH=true` in the hub environment —
Beszel reads this env var on every restart and overrides whatever
PocketBase holds, so it belongs in the flake, not in the UI. Never flip
it in PocketBase directly.

Pros / cons of disabling password login (rollout-plan ask):

- **Pro:** no second credential to remember or rotate; the shared
  Keycloak password policy, SMTP forgot-password flow, and (later) the
  restrict-client-auth gate apply; no password phishable on the Beszel
  origin.
- **Pro:** it is reversible without click-ops — flip the env line and
  the hub restart accepts the sops-stored admin password again.
- **Con:** authentication now depends on Keycloak (srv-prod-1) being
  up; if it is down, the hub cannot be logged into until it returns.
  Mitigations: the break-glass path is LAN-local (flip the env line on
  directions or ssh in; the `hub-admin-password` sops secret stays in
  place), and the Keycloak break-glass runbook lives in
  `tofu/keycloak/README.md`.
- **Con:** with password auth off, the only door is the OIDC provider
  config in the PocketBase DB; a fat-fingered provider change is
  recovered over ssh (env flip or PocketBase backup), not via the UI.

Alternatives rejected: keeping password login beside SSO (drifts
against the rollout goal and leaves a phishable local credential);
`USER_CREATION=true` (no second person to provision; revisit when a
household user is added — Beszel requires manual `systems`-to-user
assignment anyway); auth-proxy in front of the hub (native OIDC exists,
and the agents' WebSocket/token path would gain an unnecessary proxy in
the middle).

## Part A — tofu client ✅ (merged with this plan)

`tofu/keycloak/client-beszel.tf` per the existing one-file-per-client
convention; the `OpenTofu Keycloak` pipeline applies it on merge. The
secret seeding is a one-time operator command (framework-13, from the
repo root — the age identity is not available in CI sessions):

```bash
read -rs -p "Beszel client secret (generate e.g. with: head -c 32 /dev/urandom | base64): " SECRET; echo
printf '%s' "$SECRET" | jq -R . | \
  sops set tofu/keycloak/secrets.json '["beszel_client_secret"]' --value-stdin
unset SECRET
```

Keep the value around for Part B — it must be pasted into the PocketBase
UI so both sides match (view it later with
`sops -d --extract '["beszel_client_secret"]' tofu/keycloak/secrets.json`).

## Part B — PocketBase click-ops ⏳ (operator, ~5 minutes)

Ordered so the hub's login behavior changes only after the Keycloak
client exists and is applied:

1. Confirm the client is live in the realm: the OpenTofu Keycloak
   pipeline is green, and `https://account.ritter.family/realms/homelab`
   → Clients → `beszel` shows the redirect URI.
2. Log into the hub UI at `https://beszel.ritter.family` (local
   password, last time), then open the superuser settings at
   `https://beszel.ritter.family/_/#/settings`.
3. Toggle **off** "Hide collection create and edit controls", save.
4. Collections → `users` → gear icon → **Options** → **OAuth2**:
   enable it, **Add provider** → *OpenID Connect* — Beszel offers three
   generic slots (*OIDC*, *OIDC2*, *OIDC3*) for custom OIDC providers;
   they are interchangeable containers (pick any free one so the login
   button carries the display name you want), per
   https://beszel.dev/guide/oauth. Fill in:
   - Client id: `beszel`
   - Client secret: the sops value from Part A
   - Display name: `Keycloak`
   - Auth URL: `https://account.ritter.family/realms/homelab/protocol/openid-connect/auth`
   - Token URL: `https://account.ritter.family/realms/homelab/protocol/openid-connect/token`
   - Fetch user info from: *User info URL* →
     `https://account.ritter.family/realms/homelab/protocol/openid-connect/userinfo`
   - Support PKCE: **checked**
   Then "Set provider config" and save the collection.
5. Toggle "Hide collection create and edit controls" back **on**, save.
6. Log out, sign in with **Keycloak** (the new button on the login
   page): complete the realm flow, and confirm the SSO login lands in
   the existing admin account — all six systems, alert rules, and
   history intact, admin badge present.

Stage gate: do not proceed to Part C until 6 has passed. While it
hasn't, the local password login still works and nothing is locked out.
✅ Passed 2026-11-09 (first SSO login landed in the admin account).

### Part B addendum — SMTP mailer via Brevo ✅ (click-ops, 2026-11-09)

Configured in the same sitting as the OAuth provider (hub Settings →
SMTP, Brevo credentials per the per-service-sender pattern from the
Forgejo plan). This one is **not** declarable: mail settings are
PocketBase app state in `beszel.db`, without an env override — the full
hub env list (https://beszel.dev/guide/environment-variables) has no
SMTP entry, and the nixpkgs module exposes no mail options (the Forgejo umbrella had a declarative
mailer; Beszel doesn't). The only in-code path would be a bespoke
Forgejo-style `ExecStartPost` superuser-API script — noted as a
possible follow-up, not built. The DB state survives rebuilds, so the
click-ops is the config.

Code-able follow-ups discovered in the env list: setting
`APP_URL=https://beszel.ritter.family` in the hub env (used for links
in emails/notifications, now that mail exists), and `MFA_OTP=true`
(email one-time password MFA, requires SMTP — now available).

## Part C — disable password login ✅ (one-line env change)

After the first SSO login is confirmed (✅ 2026-11-09), password login
is disabled declaratively alongside `APP_URL`:

```diff
@@ modules/nixos/beszel-hub.nix @@
       services.beszel.hub = {
         enable = true;
-        environment.USER_EMAIL = config.systemConstants.adminEmail;
+        environment = {
+          USER_EMAIL = config.systemConstants.adminEmail;
+          # Links in emails / notifications use this instead of the
+          # request origin — the hub serves via the public FQDN.
+          APP_URL = "https://beszel.ritter.family";
+          # SSO is the only door (Part C of docs/plans/beszel-keycloak-sso.md);
+          # the break-glass is this line's removal + sops hub-admin-password.
+          DISABLE_PASSWORD_AUTH = "true";
+        };
         environmentFile = config.sops.templates."beszel-hub-env".path;
       };
```

Merge; comin switches directions, the hub restarts, and the password
option disappears from the login page while Keycloak SSO keeps working.
`hub-admin-password` deliberately **stays** in sops — it is the
break-glass credential for the env-flip rollback.

## Verification

```bash
# health endpoint stays public (gatus keeps working)
curl -s -o /dev/null -w '%{http_code}' https://beszel.ritter.family/api/health
# expected: '200'

# password login is gone after Part C
curl -s https://beszel.ritter.family/api/collections/users/auth-methods | jq
# expected: password method absent, oidc present

# SSO end-to-end
curl -s "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=beszel&response_type=code&redirect_uri=https%3A%2F%2Fbeszel.ritter.family%2Fapi%2Foauth2-redirect&scope=openid&state=probe" -o /dev/null -w '%{http_code}\n'
# expected: '302' — Keycloak accepted client + redirect URI (no PKCE probe
# here; the browser flow carries the challenge, cf. the Forgejo plan)
```

## Rollback

- Part C: remove the env line, redeploy — password login returns.
- Part B: PocketBase → users collection → OAuth2 → remove/disable the
  provider (or `tofu destroy`-the-client equivalent by setting
  `enabled = false` in `client-beszel.tf` and applying).

## Cleanup / follow-ups

- ⏳ After Part C lands: update the Beszel row in
  [`keycloak-sso-rollout.md`](keycloak-sso-rollout.md) to ✅ and archive
  this plan per AGENTS.md.
- ⏳ `docs/homelab.md` + directions homepage entry only if the login
  model changes something user-visible (tile stays; no URL change).
- When a second person ever needs hub access: set `USER_CREATION=true`
  or pre-create the user in PocketBase, then assign systems to them —
  and note Beszel's per-user `systems` assignment in the hub config.
