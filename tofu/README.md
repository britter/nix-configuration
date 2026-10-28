# OpenTofu infrastructure

The infrastructure-as-code (OpenTofu) configurations for the home lab moved
here from the `britter/home-lab` repository, and live in one dedicated root
per domain — each one is an independent OpenTofu project with its own
`secrets.json` and README:

- [`tofu/dns`](dns/README.md) — DNS (Cloudflare, Tailscale devices)
- [`tofu/keycloak`](keycloak/README.md) — Keycloak realm and OIDC clients
- [`tofu/network`](network/README.md) — UniFi network (VLANs, zones, firewall policies)
- [`tofu/object-storage`](object-storage/README.md) — Garage buckets and keys
- [`tofu/proxmox`](proxmox/README.md) — the Proxmox VMs

Secrets: each root contains a sops-encrypted `secrets.json`; rules for them
are in [`tofu/.sops.yaml`](.sops.yaml), relative to this directory. Locally,
enter any root directory and `direnv allow` — the `.envrc` decrypts
`secrets.json` for the state bucket and loads the shared dev shell from the
repository root flake (OpenTofu, sops, jq, unifly).

CI: each root has its own pipeline (see `.github/workflows/tofu-*.yaml`);
plans are commented on PRs, applies run only on `main`.
