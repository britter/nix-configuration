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
