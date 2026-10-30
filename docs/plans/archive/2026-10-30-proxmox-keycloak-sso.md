# Proxmox VE on pve: second Keycloak client

**Status:** complete (2026-10-30), archived per AGENTS.md. The
`OpenTofu Keycloak` pipeline applied `keycloak_openid_client.pve`
(secret committed to `tofu/keycloak/secrets.json` in 1.1 beforehand),
the PVE realm `keycloak` was created on the hypervisor via `pveum`
(PVE 9.2.21, issuer/client-id/claims as declared below), the
authorization-endpoint probe and the first SSO login landed in
`bene@keycloak`, and Operator granted `Administrator` on `/` after the
zero-privilege window (pveum acl modify / --users bene@keycloak --roles
Administrator) — confirmed by the operator 2026-10-30. `root@pam`
break-glass is untouched. See also the README gate-section correction
merged with Part 1 (vanilla Keycloak cannot gate a client per user;
`keycloak-restrict-client-auth` is the future path).

Builds on the Keycloak deployment
(archived at
[`docs/plans/archive/2026-10-29-keycloak-sso-on-srv-prod-1.md`](archive/2026-10-29-keycloak-sso-on-srv-prod-1.md):
realm `homelab`, issuer `https://account.ritter.family/realms/homelab`)
and follows the Forgejo client pattern
([`2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md`](archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md), PR #332). The
hypervisor itself (PVE at `192.168.10.10`, published via
`https://pve.ritter.family` → directions → :8006) is **not** NixOS- or
tofu-managed; its OIDC realm is one-time `pveum` state, documented like
the rest of the manual setup in `docs/homelab.md`.

Marking legend: ✅ done, ⏳ pending, [ ] not started. The gate for Part 2
is the `OpenTofu Keycloak` pipeline having applied
`keycloak_openid_client.pve`; the goal is the first SSO login landing in
`bene@keycloak` with Administrator on `/`.

## Chosen approach

The Keycloak side is tofu-managed like every other client: a
`keycloak_openid_client.pve` resource in a new `tofu/keycloak/client-pve.tf`
(one file per client, following `client-forgejo.tf`), applied by the
existing `OpenTofu Keycloak` pipeline on merge. The PVE side is a single
imperative `pveum realm add` on the hypervisor (its config lives in the
cluster file `/etc/pve/domains.cfg`, pmxcfs-managed — the PVE equivalent
of Forgejo's auth source in its database). No NixOS host changes and no
sops host file: the client secret is operator-generated, stored once in
`tofu/keycloak/secrets.json`, and handed to the hypervisor over SSH
stdin (no host sops store exists for pve — it is not in any key group;
see *Deliberately unchanged*).

Client settings: confidential, standard flow only, no direct access
grants, PKCE `S256` **enforced** (PVE ≥ 9 does PKCE entirely server-side
via `proxmox-openid` — it generates the challenge/verifier per login and
the verifier never leaves the hypervisor), redirect URI exactly
`https://pve.ritter.family` (the GUI sends its window origin as
`redirect-url`, see below), secret from `secrets.json` (every apply
re-sends exactly this value, rotation runbook below).

SSO users log in as `<preferred_username>@keycloak` with
`username-claim = username` and `autocreate` on: first login creates the
PVE user with **zero privileges** — PVE's own ACL system is the gate.
Decision (2026-10-29): after the first login, `bene@keycloak` gets
**Administrator on `/`** — same power as `root@pam` today, mirroring the
Forgejo pattern (SSO login keeps the admin badge). `root@pam` is
untouched and remains break-glass.

**Correction to the tofu/keycloak README (part of this rollout).** The
README's "Restricting who can use a client" section prescribes a
tofu-only IdP gate (realm role + Authorization Services + role policy +
permission) and claims "Users without the role are rejected by Keycloak
at the authorization step". That is factually wrong for standard
authorization-code logins: Keycloak's policy enforcement only evaluates
RPT/UMA permission requests; vanilla Keycloak happily logs any realm
user into any enabled client regardless of auth-services policies
(confirmed by the Authorization Services Guide's scoping and by
keycloak/keycloak discussion #20779 and the reports it links). The only
in-Keycloak mechanism that actually gates a client per user is the
third-party authenticator
[`sventorben/keycloak-restrict-client-auth`](https://github.com/sventorben/keycloak-restrict-client-auth).
Decision: **not** deployed — the realm is admin-provisioned with
registration off (the userbase *is* the allow-list), PVE's ACL system
grants auto-created users nothing until explicit `pveum acl modify`, and
an IdP-hosted extension + flow surgery is disproportionate for a
one-person realm. The README gets corrected to state this, with the
extension recorded as the future path when the realm grows and services
must diverge. No gate resources ship in this plan.

Alternatives: `pveum` vs. web UI to create the realm — CLI chosen
because it is scriptable from the runbook and avoids a long hand-typed
secret in the UI; the web UI produces the same `domains.cfg` entry.
`username-claim = email` was rejected (usernames should match the
Keycloak username, not an e-mail address); `username-claim = subject`
was rejected (Keycloak `sub` is a random UUID — unreadable user IDs).
Managing `domains.cfg` via tofu was rejected: the `Telmate/proxmox`
provider (3.0.2-rc10) has no realm/domain resource at all, so PVE's
realm is manual state, documented — the same trade Forgejo accepted for
its auth-source state in its database.

## Why there is no ordering gate (unlike Forgejo)

Part A (Forgejo) needed a staged mailer-first rollout because an SSO
attempt before the e-mail was fixed would auto-register a wrong account.
None of those hazards exist here:

- PVE already authenticates `root@pam` locally; adding a realm changes
  the login dialog, not the password path.
- `autocreate` cannot create a *conflicting* identity: users are
  realm-scoped (`bene@keycloak` never collides with `root@pam`), and an
  auto-created user starts without any permission.
- The Keycloak client can be applied by the pipeline before the PVE
  realm exists — an unused client is inert, and there is nothing to
  click-ops "before".

So the two parts are independent and can even be done in either order;
stating them as Part 1 → Part 2 is only for the plan's readability.
comin is untouched throughout: no NixOS host switches happen, and the
`OpenTofu Keycloak` pipeline applying on merge does not restart any
service. The only live event is the `pveum` command on the hypervisor.

## Step 0 — confirm the hypervisor ✅

Run on the operator machine (framework-13; reach the hypervisor by IP —
`pve.ritter.family` resolves to directions, not to the hypervisor's
SSH):

```bash
ssh root@192.168.10.10 'pveversion; echo ---; pveum realm list; echo ---; pveum user list | cut -c1-160'
```

Confirmed 2026-10-30: `pve-manager/9.2.21`, realms `pam` + `pve`, user
`root@pam` only (the tofu API token is a sub-token of `root@pam`, not a
separate user — nothing extra in the inventory). **`pveversion` ≥ 9 →**
the PKCE attribute stays in the resource as written (the PKCE logic
lives in `proxmox-openid`/`libpve-rs-perl` and is present in the 9.x
line).

## Part 1 — the Keycloak client + documentation correction

### 1.1 Secrets (idempotent: no — `sops set` overwrites; run once) ⏳

Same pattern as Forgejo's B.1: operator-generated, one store. There is
**no** second store here — the hypervisor receives the value over SSH
stdin in Part 2, and `domains.cfg` keeps its own copy afterwards.

```bash
SECRET=$(openssl rand -base64 24 | tr -d '/+=')
printf '%s' "$SECRET" | jq -R . | \
  sops set tofu/keycloak/secrets.json '["pve_client_secret"]' --value-stdin
unset SECRET
```

Run from the repo root, like the Forgejo plan's B.1. Verify structurally
before opening the PR (sops keeps keys visible):

```bash
grep -n 'pve_client_secret' tofu/keycloak/secrets.json
# expected: "pve_client_secret": "ENC[...]"
```

Do **not** create the `pve` client in the Keycloak admin console by
hand — the pipeline owns it; the console *Regenerate secret* button is
break-glass only (mirror any regenerated value into `secrets.json` or
the next apply reverts it, same rule as Forgejo's client).

### 1.2 Repo changes

@@ tofu/keycloak/client-pve.tf @@ (new file — sibling of
`client-forgejo.tf`)

```hcl
# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "pve" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "pve"
  name      = "Proxmox VE"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # PVE does PKCE entirely server-side: proxmox-openid generates the
  # challenge/verifier pair per login and redeems the code with its own
  # verifier (the verifier never leaves the hypervisor). Enforceable
  # since the 9.x line; confirm `pveversion` ≥ 9 before shipping this
  # attribute (Step 0).
  pkce_code_challenge_method = "S256"

  # Operator-generated and seeded into sops (tofu/keycloak/secrets.json).
  # PVE keeps its own copy in /etc/pve/domains.cfg, set once via pveum —
  # rotation runbook: docs/plans/archive/2026-10-30-proxmox-keycloak-sso.md → Known effects.
  client_secret = data.sops_file.secrets.data["pve_client_secret"]

  # The PVE web GUI sends its window origin as the IdP redirect-url
  # (pve-manager LoginWindow.js: `const redirectURL = location.origin`),
  # so the URI is the exact origin without a path or trailing slash.
  # Logins opened at https://<ip>:8006 send a different origin and fail
  # Keycloak's redirect check — the proxied FQDN is the one supported
  # entry point.
  valid_redirect_uris = [
    "https://pve.ritter.family"
  ]
}
```

Deliberately absent from the client, with reasons: no
authorization-services block or `*_authorization_*` resources (the
chosen-approach section above explains why, and the corrected README
records the working future path), no `web_origins`/`admin_url` (PVE is
a same-origin browser flow, not a CORS consumer, and has no
admin-endpoint callback to notify).

@@ tofu/keycloak/README.md @@ — rewrite the "Restricting who can use a
client" section (the numbered recipe points 1–3 plus the "Lock both
layers when onboarding PVE" paragraph) to the corrected facts:

- **In-Keycloak gating of a client does not exist in vanilla Keycloak.**
  Authorization Services policies/permissions (realm role + policy +
  permission, ENFORCING) evaluate only RPT/UMA permission requests; a
  plain authorization-code login is never stopped by them — a user
  without the role still gets tokens for the client (cf. the
  Authorization Services Guide, keycloak/keycloak discussion #20779,
  and the `sventorben/keycloak-restrict-client-auth` README's own
  "policy enforcement" note).
- **The working future path** when a client must only be usable by
  specific people: deploy
  [`sventorben/keycloak-restrict-client-auth`](https://github.com/sventorben/keycloak-restrict-client-auth)
  as a JAR in the Keycloak NixOS module (package override), register it
  in the browser flow, and gate the client behind a realm role — tofu
  has the flow resources to manage the binding, but this adds a
  third-party extension to the IdP and has not been done (decision
  2026-10-29).
- **Today the gate is each application's own authorization model**, with
  the realm's admin-provisioned userbase as the outer shell: PVE by its
  ACL system (`pveum acl`; auto-created SSO users start with zero
  privileges — exercised again in this rollout's 2.4), Forgejo by the
  e-mail-activation gate its Part A deployed. Lock the layers that
  actually exist; do not build the ones that only look like they exist.
- Also fixes the resource name: role assignments to a user are managed
  by `keycloak_user_roles` (v5.10; there is no
  `keycloak_user_realm_roles` resource — that name exists only as a
  *data source*).

@@ tofu/keycloak/users.tf @@ — header-comment fix: the comment says
"Per-user roles that gate a service (e.g. a future PVE hypervisor
access gate) go into the service's client file; see the README
'Restricting who can use a client' section" — reword to point at the
corrected README (per-**user** gating of a service is a no-op in
vanilla Keycloak; per-**service** access lives in the service's own
authorization model; the future extension path is in the README).

@@ docs/homelab.md @@ — add a "### Proxmox VE" subsection under
"Manual setup" documenting the realm as it will exist after Part 2
(command form without the secret value):

```
### Proxmox VE

OIDC realm `keycloak` backed by the Keycloak `homelab` realm (client
`pve`, tofu-managed in tofu/keycloak/client-pve.tf). Created once via:

    pveum realm add keycloak --type openid \
      --issuer-url https://account.ritter.family/realms/homelab \
      --client-id pve --client-key <secret-from-sops/tofu-keycloak> \
      --username-claim username --autocreate 1

Auto-created users (`<username>@keycloak`) have no privileges until
granted via `pveum acl modify`; `root@pam` is break-glass. A recreated
hypervisor needs this command again plus `pveum acl modify`.
```

### 1.3 Verify locally, open the PR

```bash
nix fmt                                 # treefmt gates everything, incl. the .md files
cd tofu/keycloak
tofu fmt -check
tofu validate                           # provider plugins already fetched
tofu plan                               # ⏳ expected: + keycloak_openid_client.pve, nothing else
```

The PR's pipeline plan comment must show `+ keycloak_openid_client.pve`
**only** (documentation edits are config-neutral). A `401` means
Keycloak rejected the provider credentials — see the archived Keycloak
plan's section 1.5, step 6. Merge; the pipeline applies the client; no
comin event, no restart anywhere. **At this point the gate for Part 2 is
met.**

Rollback (Part 1): `git revert`; the next pipeline apply deletes the
client — state-based, no manual Keycloak action. The PVE realm does not
exist yet, so nothing else changes.

## Part 2 — the PVE realm + first login

### 2.1 Hand the secret to the hypervisor (idempotent: no) ⏳

framework-13 → pve. The secret moves through SSH stdin into a
root-readable file; the `pveum` command in 2.2 reads it from the file, so
it is never an argument of an interactive command or on the clipboard:

```bash
# Pull the value straight out of the encrypted store — never the clipboard:
SECRET=$(sops -d tofu/keycloak/secrets.json | jq -r .pve_client_secret)
printf '%s' "$SECRET" | ssh root@192.168.10.10 \
  'umask 077 && cat > /root/.pve-oidc-secret'
unset SECRET
```

(`ssh root@192.168.10.10`, not `pve.ritter.family`: the DNS name is an
alias of directions and reaches directions' shell.)

### 2.2 Create the realm (idempotent: no — run once) ⏳

Run **on the hypervisor shell** (`ssh root@192.168.10.10`):

```bash
pveum realm add keycloak \
  --type openid \
  --issuer-url https://account.ritter.family/realms/homelab \
  --client-id pve \
  --client-key "$(cat /root/.pve-oidc-secret)" \
  --username-claim username \
  --autocreate 1
shred -u /root/.pve-oidc-secret
```

Notes:

- Bash history records the line as typed — `$(cat …)` stays unexpanded,
  so the secret does not land in history. `pveum` itself passes it to
  pmxcfs; `domains.cfg` stores the client key in plain text next to the
  other realm secrets, readable only by root (accepted — see Known
  effects).
- `--username-claim username` makes PVE log SSO identities in as
  `bene@keycloak` (it reads Keycloak's `preferred_username` claim).
  Unique and immutable per realm user (tofu-managed users do not edit
  their own username in the account console), which is exactly what the
  PVE wiki's warning demands for the `username` claim.
- `--autocreate 1` is what lets the *first* login create
  `bene@keycloak`; without it every login of an unknown user fails. The
  created user has no privileges — see Known effects.
- Keycloak request scopes default to `email profile` (openid added by
  PVE's OIDC stack); the `homelab` realm issues `preferred_username` in
  the ID token and userinfo endpoint — nothing to change there.
- If `pveum` errors with an option name changed by a future PVE
  release: `pveum realm add --help`.

If any option is mis-keyed: `pveum realm remove keycloak` (the PVE realm
id is cluster-local state; removing is harmless before any login) and
re-run.

### 2.3 First SSO login (the goal) + authorization-endpoint probe ⏳

Fresh/incognito window → `https://pve.ritter.family` → the login dialog
lists the new `keycloak` realm; selecting it turns the button into
**"Login (OpenID redirect)"** → click → redirect to
`account.ritter.family/realms/homelab` → sign in as `bene` → back on
PVE's login route with the ticket issued to **`bene@keycloak`**.

If instead Keycloak shows an error page before its login form, the two
usual causes are exactly the two things this plan set: redirect
mismatch (`https://pve.ritter.family` vs. an enter-at-IP origin) and the
enforced PKCE against a < 9 hypervisor (Step 0 was skipped) — both
diagnosable from Keycloak's admin console (realm `homelab` → Events →
Login events, filter client `pve`).

A pre-check without touching the browser (run from framework-13 after
Part 1's apply) — mirrors the Forgejo plan's authorization-endpoint
probe. It requests the authorize endpoint **with the registered
redirect URI and deliberately without a `code_challenge`**, and looks
not just at the numeric status but at where the 302 points:

```bash
curl -sS -o /dev/null -D - \
  "https://account.ritter.family/realms/homelab/protocol/openid-connect/auth?client_id=pve&response_type=code&state=probe&redirect_uri=https%3A%2F%2Fpve.ritter.family" \
  | sed -n '1p; /^[Ll]ocation:/p'
```

Keycloak validates the client id and the exact registered
`redirect_uri` right at this endpoint, so one response proves both:

- **PKCE enforced (9.x path):** `302` whose `Location:` is
  `https://pve.ritter.family?state=probe&error=invalid_request&error_description=Missing…code_challenge…`
  — the error an enforced challenge *should* produce, which
  simultaneously proves the client exists, the origin-only redirect
  URI matched, and the enforcement is active (the same shape as the
  Forgejo probe's "Missing parameter: code_challenge_method").
- **PKCE not enforced (8.x fallback):** `302` to the realm's login
  page (`.../openid-connect/auth?...`) — proves client + redirect URI.

Anything else (`404` unknown client, a `redirect_uri` error) points at
Part 1's apply or a URI typo. The probe never yields a code, and the
throwaway `state` never becomes a ticket; the first *real* login is
what completes the flow.

### 2.4 Unprivileged-login check + Administrator grant ⏳

Immediately after 2.3's first login, **before granting anything**,
confirm the auto-created user is unprivileged while signed in as
`bene@keycloak`: the GUI loads but shows no resources and all actions
fail with permission errors. Then grant, as `root@pam` in the GUI or
via the shell:

```bash
pveum user list | grep keycloak         # expect: bene@keycloak, the autocreate from 2.3
pveum acl modify / --users bene@keycloak --roles Administrator
```

In the confirm run as `bene@keycloak`: full datacenter view, VM
lifecycle, node shell — the Forgejo admin-badge outcome, chosen
2026-10-29. The grant is one state change in `user.cfg`; it is recorded
in `docs/homelab.md` (1.2) so a rebuilt hypervisor is recoverable from
the repository alone. Undo at any time with
`pveum acl modify / --delete --users bene@keycloak --roles Administrator`.

### 2.5 Rollback (Part 2) ⏳

```bash
pveum realm remove keycloak        # drops the login-dialog entry; root@pam unaffected
pveum acl modify / --users bene@keycloak --delete --roles Administrator
pveum user remove bene@keycloak
```

git-revert Part 1 and let the pipeline apply: the Keycloak client is
deleted state-based. Reverting only one part: a Keycloak client without
a realm is inert; a realm without a client fails logins with an IdP-side
"client not found" — both leave `root@pam` fully usable at all times.

## Known effects

- **The client secret lives in two state stores that nothing can
  cross-read.** `tofu/keycloak/secrets.json` (git-sops, framework-13 +
  runners) is the source of truth; `/etc/pve/domains.cfg` on the
  hypervisor keeps the plaintext copy the `pveum` command wrote.
  Rotation: generate a new secret, `sops set` it (key
  `pve_client_secret`), merge — the pipeline apply re-sends it to
  Keycloak — then re-run the 2.1 transfer (which now reads the *new*
  value from `secrets.json`) and on the hypervisor run
  `pveum realm modify keycloak --client-key "$(cat /root/.pve-oidc-secret)"`
  plus `shred -u` (2.2's hygiene). Between the apply and
  `realm modify`, SSO logins fail with `invalid_client` while
  `root@pam` is unaffected (Forgejo's `update-oauth` analog). The
  Keycloak console's *Regenerate secret* button stays **break-glass
  only**: the next apply reverts it unless `secrets.json` is mirrored
  first.
- **Enforced PKCE requires PVE ≥ 9** (the PKCE logic lives in
  `proxmox-openid`/`libpve-rs-perl`, entirely server-side). On an 8.x
  hypervisor an enforced client rejects every login; the plan ships the
  attribute only for ≥ 9 and otherwise leaves it off (Step 0).
- **Logins must enter through the proxied FQDN.** The GUI sends its own
  window origin as `redirect-url`, so opening the UI directly at
  `https://192.168.10.10:8006` yields an origin Keycloak does not
  accept. The wildcard DNS (`*.ritter.family` → directions → :8006
  buffering-tuned vhost) is the supported path, and `root@pam` works
  from any origin — that's the escape hatch if directions is down.
- **Auto-created users are born unprivileged.** `bene@keycloak` could
  do nothing until 2.4 granted Administrator on `/`. Anyone the realm
  ever auto-creates (a future `keycloak_user` with a new username) also
  starts at zero — the gate is real, at PVE's layer, and every grant is
  one auditable `pveum acl modify`.
- **Automation is invisible to SSO (Forgejo precedent).** The Telmate
  `proxmox` provider's API token (`pm_api_token_*` in
  `tofu/proxmox/secrets.json`) authenticates `root@pam`; realm changes
  never touch API-token auth. PVE API tokens minted for any user (realm
  users included), and the beszel/backup agent traffic, keep working
  unchanged.
- **Transient SSO unavailability on Keycloak deploys** (~15–30 s
  restart window per srv-prod-1 switch, from the archived Keycloak
  plan's Known effects). `root@pam` is unaffected while Keycloak is
  down; so is the API-token path the tofu `proxmox` root uses.
- **The realm edits the login dialog globally.** Every PVE login
  (native UI, xterm/NoVNC consoles, the PVE 9 mobile app) now offers a
  `keycloak` realm choice. Realm selection does not change what a
  session can do relative to today; `root@pam` stays in the list and
  can be re-selected for break-glass.
- **`domains.cfg` keeps the client secret in clear text** visible to
  root only (PVE stores LDAP bind passwords the same way). This is
  PVE's standard behavior; mirrored by the same acceptance the realm's
  SMTP config got in the archived Keycloak plan.
- **`pveversion` output belongs in the plan status** — when Step 0
  lands, record the confirmed version here; on a rebuilt hypervisor the
  PKCE attribute decision (Step 0) and `docs/homelab.md`'s Proxmox VE
  section are the recovery path.

## References searched

Changed:

- `tofu/keycloak/client-pve.tf` — new: the `pve` OIDC client (Part 1)
- `tofu/keycloak/README.md` — correction of the per-service gate section
  (Part 1)
- `tofu/keycloak/users.tf` — header-comment fix pointing at the
  corrected README (Part 1)
- `docs/homelab.md` — new "### Proxmox VE" subsection under
  "Manual setup" (Part 1; describes the Part 2 result)
- `tofu/keycloak/secrets.json` — `pve_client_secret` via `sops set`
  (1.1)
- pve hypervisor state (not git): `/etc/pve/domains.cfg` via
  `pveum realm add`, `pveum acl modify` on `user.cfg` (Part 2)

Deliberately unchanged, with reasons:

- **`tofu/proxmox/`**: the Telmate provider manages VMs with a
  `root@pam` API token (provider.tf) — unrelated to login realms, and it
  has no realm resource, so PVE-side auth stays click-ops/pveum.
- **DNS (`tofu/dns`)**: `pve.ritter.family` exists via the global
  wildcard → directions; no new record.
- **directions' https-proxy module**: the `pve.ritter.family` vhost
  already proxies :8006 (with the task-log buffering note in place);
  SSO callbacks are plain browser redirects needing nothing extra.
- **gatus / homepage**: the Proxmox dashboard card exists
  (`modules/nixos/homepage.nix`); monitoring of the hypervisor is not
  this plan's subject.
- **NixOS hosts / comin**: no module changes at all — the rollout's
  only live events are the tofu pipeline apply and two `pveum`
  commands.
- **`.sops.yaml` / `tofu/.sops.yaml`**: `secrets.json` is already
  covered by the generic `*/secrets.json$` rule (framework-13 +
  github-runners); there is no sops store for the hypervisor to add a
  rule for.
- **Keycloak realm config**: no flows, scopes, or mappers touched —
  `preferred_username` (profile scope) is what the `username` claim
  reads, and no consent prompt is needed (client-level default).
- **PVE datacenter defaults**: TFA left unenforced on the new realm;
  `bene`'s Master-level account holds no second factor yet either (the
  Forgejo plan's provisioning notes), so enforcing TFA here would
  create an unloggable realm. Revisit when a root-level identity gets a
  passkey.

Upstream sources consulted:

- PVE User Management wiki — Linked realms → OpenID Connect
  (`issuer-url`, `client-key`, `autocreate`, `username-claim`,
  Keycloak warning; the OIDC callback behavior verified in
  `proxmox/pve-manager` master's LoginWindow.js), retrieved 2026-10-29/30.
- `proxmox/pve-manager` `www/manager6/window/LoginWindow.js` (master):
  the OpenID branch POSTs `location.origin` as `redirect-url` to
  `/api2/extjs/access/openid/auth-url`, and completes the login by
  POSTing `state`+`code` to `/api2/extjs/access/openid/login`.
- `proxmox/proxmox-widget-toolkit` `src/Utils.js#getOpenIDRedirectionAuthorization`
  (back-channel param parsing).
- lore.proxmox.com, pve-devel Sept 2026 (OIDC callback activity
  thread): PVE performs PKCE entirely server-side via
  `proxmox-openid`'s `PrivateAuthState` — grounds the `S256` enforcement.
- `keycloak/terraform-provider-keycloak` v5.10.0 docs:
  `openid_client` (`pkce_code_challenge_method`, `authorization {}`
  block), `openid_client_role_policy`, `user_roles`,
  `openid_client_authorization_permission`.

## Status

- [x] Repository exploration (Forgejo files, homepage card, proxy entry,
      tofu roots, upstream PVE/Keycloak sources) — recorded above
- [x] Step 0 (2026-10-30): `pve-manager/9.2.21`, realms `pam`+`pve`,
      user `root@pam` only — PKCE `S256` confirmed enforceable; the
      resource ships the attribute as written
- [x] 1.1 `pve_client_secret` stored in secrets.json (operator `sops set`,
      structural check passed) — done before the PR, confirmed in
      production by the successful token exchange
- [x] 1.2 code prepared on the `pve-sso` branch: `client-pve.tf`
      (PKCE `S256` kept, per Step 0), README gate-section correction,
      `users.tf` comment fix, `docs/homelab.md` Proxmox VE section;
      `tofu fmt -check` exit 0, `tofu validate` Success,
      `nix fmt`/treefmt clean
- [x] 1.3 PR #335 merged; pipeline applied `keycloak_openid_client.pve`
      (evidenced by the probe and first login afterwards)
- [x] 2.1 secret transferred over SSH stdin into `/root/.pve-oidc-secret`,
      shredded after 2.2
- [x] 2.2 realm `keycloak` created on the hypervisor; verifies correctly
      (realm list, discovery from pve, probe, secret hash-match — the
      working login is the strongest of the four)
- [x] 2.3 first SSO login lands in `bene@keycloak` (confirmed by
      operator 2026-10-30)
- [x] 2.4 Administrator on `/` granted to `bene@keycloak`
      (`pveum acl modify / --users bene@keycloak --roles Administrator`,
      confirmed 2026-10-30); the pre-grant zero-privilege window was not
      explicitly observed in the browser, but the model was verified
      structurally (autocreate grants nothing)
- [x] docs: `docs/homelab.md` Proxmox VE section matches what shipped
