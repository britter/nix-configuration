# nix-configuration

Declarative, flake-based configuration for all of my machines — a desktop
laptop and a fleet of home-lab servers — plus the
[OpenTofu](https://opentofu.org) code describing the infrastructure they run
on. Everything lives in code: machines, users, services, dotfiles, networks,
and VMs. Nothing is configured imperatively.

The NixOS side uses my own flavor of the
[dendritic Nix pattern](https://britter.dev/blog/2026/05/11/exploring-the-dendritic-nix-pattern/)
(flake-parts plus import-tree): every feature is a named *aspect*, and hosts
compose aspects by importing them. See `AGENTS.md` for the details — it is
written for coding agents, but equally useful for humans.

The OpenTofu side was merged from the separate `britter/home-lab` repository
in October 2026, with full history preserved
(see `docs/plans/archive/2026-10-26-merge-home-lab.md`).

## What lives where

| Path | Contents |
| ---- | -------- |
| `modules/` | NixOS and home-manager aspects |
| `modules/hosts/<name>/` | one directory per machine |
| `tofu/` | OpenTofu infrastructure, one root per domain — see `tofu/README.md` |
| `packages/` | local packages, available as `pkgs.<name>` via the `local-pkgs` overlay |
| `templates/` | flake templates, e.g. `nix flake init -t .#minimal-dev-shell` |
| `docs/` | runbooks, homelab notes, plan documents, incident reports |

## Machines

| Host | What it is | Deployment |
| ---- | ---------- | ---------- |
| `framework-13` | desktop laptop | manual `nixos-rebuild switch` |
| `directions` | Raspberry Pi edge server: DNS adblocking, status page, homepage, HTTPS proxy | comin |
| `pve` | Proxmox VE hypervisor running the `srv-prod-*` VMs | not managed with Nix |
| `srv-prod-1`–`srv-prod-6` | Proxmox VMs running the home-lab services; `srv-prod-6` also hosts the self-hosted CI runners | comin |
| `truenas` | NAS providing the NFS backup share for `pve` | not managed with Nix |
| `srv-offsite-1` | offsite server running Garage object storage | comin |
| `minimal-server-iso` | minimal installer ISO | build artifact |

Servers deploy themselves: [comin](https://github.com/nlewo/comin) pulls this
repository and switches when `main` moves. `pve` and `truenas` are part of
the homelab but configured by hand — they are not managed with Nix. See
`docs/bootstrap.md` for how a new machine joins the fleet.

## Home lab infrastructure (`tofu/`)

The infrastructure-as-code for the home lab lives under `tofu/`, one
independent OpenTofu root per domain:

- [`tofu/dns`](tofu/dns/README.md) — Cloudflare DNS records pointing at
  Tailscale device addresses
- [`tofu/network`](tofu/network/README.md) — UniFi: VLANs, zones, firewall
  policies
- [`tofu/object-storage`](tofu/object-storage/README.md) — Garage buckets and
  keys
- [`tofu/proxmox`](tofu/proxmox/README.md) — the Proxmox VMs that run the
  NixOS servers

How it runs:

- Each root has its own pipeline (`.github/workflows/tofu-*.yaml`). PRs are
  **plan-only**, with the plan commented on the PR; applies happen only on
  `main`, serialized per root.
- The pipelines run on self-hosted runners on `srv-prod-6`, which hold the
  sops age key for decrypting credentials. The trust model and runner
  setup are documented in `docs/homelab.md`.
- State is stored remotely in the self-hosted Garage S3 instance
  (`garage.srv-prod-3.ritter.family`), one `tofu-states-<root>` bucket per
  root. Remote state is what makes the gitops flow work at all: runners can
  plan and apply without keeping state anywhere local. Reaching it requires
  the bucket credentials from the root's sops-encrypted `secrets.json`.
- Secrets are sops-encrypted `secrets.json` files, one per root; the
  encryption rules live in `tofu/.sops.yaml`. Locally, enter a root and
  `direnv allow` — the `.envrc` decrypts secrets and loads the shared dev
  shell (OpenTofu, sops, jq, unifly).
- Manual changes made outside OpenTofu (e.g. deleting a network in the UniFi
  UI) must be reconciled with `tofu state rm <resource>` before the next
  apply. Use `unifly` to triage controller state; block deletions persist
  until stale reservations and clients are cleared.

## Secrets

Two independent sops setups:

| Scope | Rules file | Secret files |
| ----- | ---------- | ------------ |
| NixOS hosts (SSH host keys, service secrets) | `.sops.yaml` | `modules/hosts/<host>/secrets.yaml`, `modules/nix/dev-shell/host-keys.yaml` |
| OpenTofu (per-root state-bucket and provider credentials) | `tofu/.sops.yaml` | `tofu/<root>/secrets.json` |

Adding a new host key to the sops store:

1. Convert the host's public SSH key to age:

```shell
nix run nixpkgs#ssh-to-age -- -i ~/.ssh/key.pub
```

2. Add an entry to the matching `.sops.yaml` for that host.
3. Create or edit the secrets file:

```shell
nix run nixpkgs#sops -- path/to/secrets.yaml
```

Rotating a key: modify the `.sops.yaml` entry, then run

```shell
nix run nixpkgs#sops -- updatekeys path/to/secrets.yaml
```

Further references: [sops-nix](https://github.com/Mic92/sops-nix),
[sops](https://github.com/getsops/sops).

## Working on this repository

- `direnv allow` (or `nix develop`) provides the dev shell with all tools.
- `nix fmt` — formatting (treefmt); run before committing.
- `nix flake check` — evaluates all hosts, home-manager configurations,
  packages, and the formatting check. It is the closest thing this repo has
  to a test suite.
- CI: the NixOS pipelines (`ci-build.yaml`, `lint.yaml`) skip `tofu/**` and
  `docs/**` changes; the tofu pipelines trigger only on `tofu/**` plus shared
  files. See `docs/homelab.md` for the runner setup.

Generic Nix commands live in `docs/nix-cheatsheet.md`.

## More documentation

- [`AGENTS.md`](AGENTS.md) — how the aspects and hosts compose
- [`docs/bootstrap.md`](docs/bootstrap.md) — bootstrapping new machines
  (NixOS, Proxmox VMs, macOS, Raspberry Pi)
- [`docs/homelab.md`](docs/homelab.md) — homelab setup notes, CI and runner
  details, trust model
- [`docs/desktop-manual-setup.md`](docs/desktop-manual-setup.md) — stateful
  changes on `framework-13` that the flake cannot express
- [`docs/plans/`](docs/plans/) — work plans and their archive
- [`docs/incidents/`](docs/incidents/) — post-mortems
- [`tofu/README.md`](tofu/README.md) and the per-root READMEs — the
  infrastructure code
