# Homelab

## Manual setup

This section lists all the things I configured manually while setting up my homelab.
All of this configuration should be part of the backups, so it's only required to refer to when setting up one of the services from sratch.

### NextCloud

#### General

1. Configured users

#### Bookmarks app

1. Configured the bookmarks app for internet access so it can fetch previews.

#### Richdocuments app

1. Configure URL of Collabora Online Server to point to the server
2. Configure Allow list to only allow 172.17.0.2 (IP of the collabora docker container)

### Proxmox VE

OIDC realm `keycloak` backed by the Keycloak `homelab` realm (client
`pve`, tofu-managed in `tofu/keycloak/client-pve.tf`). Created once via:

    pveum realm add keycloak --type openid \
      --issuer-url https://account.ritter.family/realms/homelab \
      --client-id pve --client-key <secret-from-sops/tofu-keycloak> \
      --username-claim username --autocreate 1

Auto-created users (`<username>@keycloak`, e.g. `bene@keycloak`) have no
privileges until granted via `pveum acl modify`; `root@pam` is
break-glass. A recreated hypervisor needs this command again plus
`pveum acl modify`. SSO logins only support entering via
`https://pve.ritter.family` (direct IP access registers a different
redirect origin, see `docs/plans/archive/2026-10-30-proxmox-keycloak-sso.md`).

### Beszel

All of this was configured via click-ops per
`docs/plans/archive/2026-11-09-beszel-keycloak-sso.md`; it lives in the
hub's PocketBase database and needs to be redone when rebuilding the hub
from scratch (the flake replaces the Keycloak-side parts on rebuild):

1. First user comes from the hub env on new installs (`USER_EMAIL` /
   `USER_PASSWORD` in `modules/nixos/beszel-hub.nix`, the password from
   sops `beszel/hub-admin-password`). Password login is disabled
   declaratively (`DISABLE_PASSWORD_AUTH=true`); if the env line is
   removed, the sops password works again on restart — that is the
   break-glass.
2. SMTP: hub Settings → SMTP, Brevo (per-service credentials + sender,
   same pattern as Forgejo/Keycloak in this file). Not declarable —
   PocketBase app state, no env override.
3. OIDC: PocketBase superuser settings (`https://beszel.ritter.family/_/#/settings`)
   → toggle off "Hide collection create and edit controls" → users
   collection → Options → OAuth2 → OIDC provider:
   client id `beszel`, secret from sops/tofu-keycloak
   (`beszel_client_secret`), display name `Keycloak`, auth/token/userinfo
   from `https://account.ritter.family/realms/homelab/protocol/openid-connect/*`,
   "Support PKCE" checked. Then toggle the collection-hide switch back
   on. Click "Set provider config" and save the collection.

Login works via the public FQDN only (`https://beszel.ritter.family`, the
`/api/oauth2-redirect` callback; the hub aspect's spare vhost registers a
rejected redirect origin). Agents and the `/api/health` endpoint don't
use the users collection — SSO and the password switch don't affect them.

### Home Assistant

Configured via click-ops on the HAOS device per
[`docs/plans/homeassistant-keycloak-sso.md`](plans/homeassistant-keycloak-sso.md);
it lives in UI storage (`.storage/`) and needs to be redone when rebuilding
the device from scratch (the Keycloak-side client is tofu-managed, in
`tofu/keycloak/client-homeassistant.tf` — a **public** client, no secret):

1. HACS → install `christiaangoossens/hass-oidc-auth` ("OpenID Connect/SSO
   Authentication"), restart HA.
2. Settings → Devices & Services → Add Integration → OpenID
   Connect/SSO Authentication → provider *OpenID Connect (SSO)*:
   discovery URL
   `https://account.ritter.family/realms/homelab/.well-known/openid-configuration`,
   client id `homeassistant`, **no secret**. Enable automatic user
   linking only for the initial migration login, then disable it again
   (the SSO credential stays linked).
3. Local password login stays enabled as break-glass (the companion
   apps' refresh tokens are tied to the `homeassistant` auth provider —
   do not remove that provider).

SSO works via the public FQDN only
(`https://homeassistant.ritter.family/auth/oidc/callback`); logging in at
the raw LAN address `http://192.168.20.234:8123` uses the local password.
Proxy-trust (`trusted_proxies` = directions' IP) is a UI-storage setting
— see the 2026-11-02 incident before changing the proxy's address.

## Repository layout

The declarative NixOS configuration drives infrastructure that is also
described in code next to it: the OpenTofu roots under `tofu/` (formerly the
separate `britter/home-lab` repository, merged with full history). Each
`tofu/<root>/` is an independent OpenTofu project (`dns`, `network`,
`object-storage`, `proxmox`) with its own sops-encrypted `secrets.json`;
encryption rules live in `tofu/.sops.yaml`.

CI (`.github/workflows/`):

- `tofu-<root>.yaml` — one pipeline per OpenTofu root, run only for changes
  under `tofu/<root>/` (plus shared files like `tofu/.sops.yaml` and the
  root flake). Plans are commented on PRs; applies happen only on `main`,
  serialized per root via the `tofu_latch_<root>` concurrency groups.
- `ci-build.yaml` / `lint.yaml` — the NixOS pipelines, skipped for
  tofu-only and docs-only changes.

## GitHub runners

The four runners on `srv-prod-6` (`services.github-runners.nixos-runner-1..4`)
are registered against this repository with the labels `nixos`, `x86_64`,
`trusted` (see `modules/nixos/github-runners.nix`). All tofu jobs require
`runs-on: [self-hosted, trusted]`; no job may use bare `self-hosted`, which
would match the pool implicitly (the built-in `self-hosted` label cannot be
removed). The runners hold the sops age key (secret
`github-runners/age-key`) and the GitHub PAT for registration
(`github-runners/pat`); sops decryption inside the tofu jobs works through
`SOPS_AGE_KEY_FILE`.

Trust model: this repository has no outside collaborators (its only external
contributor is Renovate, whose PRs are branch PRs, not fork PRs). No
workflow uses `pull_request_target`, and third-party actions are pinned to
SHAs. Defense in depth: fork PRs require approval before their workflows
run.

### Actions allow-list

Repository settings (Settings → Actions → General → "Actions permissions")
enforce third-party actions; these settings are UI-only (the REST API
rejects writes for personal-account repositories):

- Mode **"Allow britter, and select non-britter actions and reusable
  workflows"** with exactly these explicit patterns:
  - `DeterminateSystems/nix-installer-action@*`
  - `jlumbroso/free-disk-space@*`
- **"Allow actions created by GitHub"** is enabled (covers `actions/checkout`,
  `actions/github-script`).
- **"Require actions to be pinned to a full-length commit SHA"** is enabled.

Practical rule: before a workflow can reference a new third-party action,
its `owner/repo@*` pattern must be added to the allow-list and the reference
pinned to a full commit SHA — otherwise every run fails at workflow parse.
Renovate is kept with SHA/digest pinning (`pinDigests` via
`config:best-practices`), so its action-bump PRs stay compatible.

**Residual risk**: the runner jobs run as a fixed system user
(`github-runner`) that is a member of `nix.settings.trusted-users`. Consequently, any code the runners execute can install and build arbitrary
Nix packages as root via the nix daemon. Everything the tofu workflows run
(infrastructure jobs and the pinned GitHub Actions they invoke) is
therefore effectively root-equivalent on every co-located server;
triage any workflow change accordingly.

## Forgejo runner (Codeberg)

`srv-prod-6` also hosts one Forgejo runner (instance `codeberg`,
`forgejo-runner-codeberg.service`, see `modules/nixos/forgejo-runner.nix`
and `modules/hosts/srv-prod-6/services/codeberg-runner.nix`). It is
registered at **repo level** against
https://codeberg.org/britter/nixpkgs-pr and only executes that
repository's workflows — currently the Renovate workflow, which acts as
the dedicated `britters-bot` Codeberg account (setup documented in
`modules/hosts/srv-prod-6/services/renovate.md`).
Registration used the Forgejo UUID + token model; the token lives in sops
(`forgejo-runner/token`), the UUID is part of the nix config (not
confidential, and upstream has no `uuid_url` yet).

Trust model: jobs run in unprivileged rootful-podman containers (the runner
talks to `/run/docker.sock`, a symlink to the podman socket), capped at
`--memory=2g --cpus=1`. Containers have no nix daemon access, no host bind
mounts, and the container socket is not shared into jobs
(`docker_host: "-"`). The nixpkgs-pr repository is public, so PRs from
forks can run arbitrary container images on this runner: Forgejo gates
those behind an explicit approval for read-access authors (per run, or
standing via "Approve always", revocable), and `pull_request` workflows get
no repository secrets. On the host, the `container-egress` nftables table
limits job containers to internet egress plus DNS and the pinned
action-cache port on their podman gateway — the UniFi gateway cannot do
this filtering because container traffic NATs behind the VM's own address.
This pool is therefore much less trusted than the GitHub runner pool above;
if a job ever needs host-level capabilities or internal network access,
treat that as a trust-model change, not a config tweak. Never use
`pull_request_target` in nixpkgs-pr workflows; it combines secrets with
PR-influenced content.
