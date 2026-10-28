# forgejo-runner on srv-prod-6

**Status:** ⏳ ready to merge — code, hardening, docs, UUID, and sops token
all in place; full `srv-prod-6` toplevel builds. Pending: commit/PR/merge,
then post-deploy verification (phase 3/4 below)
**Goal:** host a Forgejo runner on `srv-prod-6` that executes the Renovate
workflow of https://codeberg.org/britter/nixpkgs-pr
(`.forgejo/workflows/renovate.yaml`).

## Approach

- Use the NixOS `services.forgejo-runner` module (forgejo-runner 13.2.0) with
  the new UUID + token connection model. Codeberg runs Forgejo 16.0.0-dev, so
  interactive runner registration (which hands out the UUID + token pair) is
  available.
- Register the runner at **repo level**
  (`https://codeberg.org/britter/nixpkgs-pr/settings/actions/runners`), so it
  only ever executes jobs from `nixpkgs-pr`. (Alternative considered: user
  level at `/user/settings/actions/runners` picks up jobs from *all* of the
  user's repos — broader blast radius, rejected.)
- Jobs run in containers: enable the existing `podman` aspect with
  `dockerSocket.enable = true`; the forgejo-runner module detects the
  `:docker` label and wires the service into the `podman` group
  automatically.
- Workflow secrets (`RENOVATE_TOKEN`, `GH_TOKEN`) are repository-level
  secrets on Codeberg — they never touch srv-prod-6 or this repository. The
  runner only needs its own connection token, stored in sops as
  `forgejo-runner/token`.

## Repo changes (already on this branch)

- `modules/nixos/forgejo-runner.nix` — generic aspect: podman with
  docker-compatible socket, instance `codeberg` with label
  `docker:docker://node:24-bookworm` (matches `runs-on: docker`; the Renovate
  workflow overrides the image via `container: image:`), per-job resource
  caps (`--memory=2g --cpus=1`), pinned action-cache proxy port, and the
  container egress policy (see below).
- `modules/hosts/srv-prod-6/services/codeberg-runner.nix` —
  `codeberg-runner-on-srv-prod-6`: sops secret `forgejo-runner/token`
  (with `restartUnits`), Codeberg connection URL + UUID.
- `modules/hosts/srv-prod-6/configuration.nix` — imports the new instance
  aspect.
- `modules/hosts/srv-prod-6/services/renovate.md` — how the Renovate
  workflow is set up: the `britters-bot` account and the two repository
  secrets.

### Container egress policy

Jobs run untrusted code on a public repository, and the UniFi gateway
(`tofu/network`) cannot filter container traffic — it NATs behind the VM's
own address, so no zone policy can target it. The policy therefore lives in
the guest, in the generic runner aspect, as the nftables table
`container-egress` (hooked at priority `-10`, before the nixos-fw accepts):

- FORWARD: job containers may only reach the internet. Traffic to RFC1918,
  the tailnet (`100.64.0.0/10`), link-local, multicast and reserved ranges
  is dropped. Container↔container on the same job network keeps working
  (`iifname == oifname` on the podman bridges); different job networks stay
  isolated.
- INPUT: containers may only reach DNS (aardvark-dns, port 53) and the
  pinned action-cache proxy (`cache.proxy_port = 32230`) on their network
  gateway. Everything else on private destination addresses (sshd, nginx,
  beszel-agent, the tailnet IP) is dropped — at priority `-10`, so it wins
  over the generic `allowedTCPPorts` accepts of the nixos-fw input chain
  (priority 0). The corresponding *accepts* render inside the nixos-fw
  chain itself (`networking.firewall.extraInputRules`): an accept in one
  nftables table does not exempt a packet from another table, so the
  nixos-fw default-drop would have swallowed them otherwise. Found by the
  post-deploy probe (`wget: bad address` inside a job container).

Side effect: `networking.nftables.enable = true` switches the NixOS firewall
rendering from the iptables to the nftables backend on this host. The
firewall options in use are backend-agnostic; nothing else on the host uses
iptables (tailscale is a plain client, no exit node or subnet routes).

Verified locally (evaluated via `nix build
path:.#nixosConfigurations.srv-prod-6.config.services.forgejo-runner.instances.codeberg.configFile`
because the new files are untracked; results hold for the tracked tree too):

- rendered `config.yaml` contains the label, `url = https://codeberg.org`,
  the UUID placeholder and
  `token_url: file:$CREDENTIALS_DIRECTORY/server__connections__codeberg__token_url`
- rendered nftables ruleset (`nftables-rules` derivation) matches the
  policy above and passes the build-time `nft check`
- unit `forgejo-runner-codeberg.service`: `after = [network-online.target
  podman.service]`, `SupplementaryGroups = [podman]`,
  `LoadCredential = server__connections__codeberg__token_url:/run/secrets/forgejo-runner/token`
- `runtimes.podman = true` (auto-detected)
- `nix fmt` reports the new files clean

Building the full toplevel currently fails on the sops manifest check
(`the key 'forgejo-runner' cannot be found`) — expected until phase 2 adds
the token to `modules/hosts/srv-prod-6/secrets.yaml`. The sops edit must be
part of the same PR, or any pipeline that builds host toplevels stays red.

## Runbook

### Phase 1 — create the runner on Codeberg (manual, UI)

1. Open https://codeberg.org/britter/nixpkgs-pr/settings/actions/runners and
   click **Create new runner**. Suggested name: `srv-prod-6`.
2. Copy the displayed **UUID** and **Token**. The UUID is not confidential;
   the token is the secret.
3. Add the two repository secrets the workflow references
   (https://codeberg.org/britter/nixpkgs-pr/settings/actions/secrets):
   - `RENOVATE_TOKEN` — a Codeberg access token for the account that renovate
     acts as (needs repository read/write to push branches and open PRs).
   - `GH_TOKEN` — a GitHub token (read-only public repo scope suffices) used
     as `GITHUB_COM_TOKEN` for API rate limits.

**Check:** the runner appears in the repo's runner list in status
"offline"/"idle". That is expected — nothing is connected yet.

### Phase 2 — feed the UUID and token into the config (local)

1. Replace the `@RUNNER-UUID@` placeholder in
   `modules/hosts/srv-prod-6/services/codeberg-runner.nix` with the UUID from
   phase 1. The UUID lives in the nix store config file by design (upstream
   has no `uuid_url`; see the FIXME in nixpkgs' `forgejo-runner.nix`).
2. Add the token to the host's sops file (idempotent: re-running with the
   same value changes nothing):

   ```
   sops modules/hosts/srv-prod-6/secrets.yaml
   ```

   Add the key `forgejo-runner: token: <token>` (top-level
   `forgejo-runner` key, nested `token`). Commit only the encrypted file.

**Check:** `rg '@RUNNER-UUID@'` finds nothing;
`sops modules/hosts/srv-prod-6/secrets.yaml -d` shows the key exists (do not
print the value in logs).

### Phase 3 — deploy through comin

1. Commit everything on this branch and merge the PR into `main`.
2. comin on srv-prod-6 pulls and switches automatically within its poll
   interval. Order is safe in both directions: the sops secret is added by
   the same switch that starts the service, and sops-nix renders secrets
   before normal units start.
3. Verify on the server:

   ```
   ssh srv-prod-6
   systemctl status forgejo-runner-codeberg.service
   journalctl -u forgejo-runner-codeberg.service | grep -i 'declared successfully'
   ```

**Check:** the unit is active, the log shows the runner declared itself, and
the runner on the Codeberg runner list flips to "idle".

### Phase 4 — verify the workflow end to end

1. Open https://codeberg.org/britter/nixpkgs-pr/actions and dispatch the
   `Renovate` workflow manually (`workflow_dispatch`).
2. The job must be picked up by `srv-prod-6` (repo-level runner is the only
   one matching `runs-on: docker`) and run the `renovate` step.

**Check:** the workflow run completes; depending on findings, Renovate opens
PRs against the repository.

### Phase 5 — verify the network hardening

The drop rules are silent by design, so verification combines observable
counters with positive/negative probes from a container that uses the same
runtime (rootful podman on srv-prod-6, default bridge `podman0` — the same
`podman*` interfaces the table matches).

1. Confirm the table is loaded and note the baseline counters:

   ```
   sudo nft list table inet container-egress
   ```

   Expected: both chains with the drop rules carrying `counter packets <n>`
   (0 right after the switch).

2. Positive probes — must succeed (proves DNS via aardvark and internet
   egress still work):

   ```
   sudo podman run --rm alpine wget -qO- -T 10 https://codeberg.org/api/v1/version
   sudo podman run --rm alpine wget -qO- -T 10 https://api.github.com/rate_limit
   ```

3. Negative probes — must time out (not refuse) and increment the forward
   drop counter from step 1. Server LAN IPs are the UniFi fixed IPs
   (`tofu/network/clients.tf`); tailscale IPs via `tailscale status`:

   ```
   # srv-prod-1's LAN IP (FORWARD, RFC1918)
   sudo podman run --rm alpine wget -T 5 -O- http://192.168.30.11/ || echo BLOCKED
   # any host's tailscale IP (FORWARD, 100.64.0.0/10)
   sudo podman run --rm alpine wget -T 5 -O- http://<tailscale-ip>/ || echo BLOCKED
   # srv-prod-6's own LAN IP (INPUT: nginx 443, sshd 22)
   sudo podman run --rm alpine sh -c 'wget -T 5 -O- https://192.168.30.16/ || nc -z -w 5 192.168.30.16 22' || echo BLOCKED
   ```

   A timeout (drop) is the expected failure mode; a connection refused
   would mean something else answered — investigate before trusting the
   policy.

4. Informational — action-cache proxy reachable on the gateway (only
   relevant for workflows using `actions/cache`; renovate does not):

   ```
   sudo podman run --rm alpine nc -z -w 5 10.88.0.1 32230 && echo REACHABLE || echo UNREACHABLE
   ```

5. No-collateral check for the iptables→nftables switch: `sudo nft list
   table inet nixos-fw` exists with the expected port accepts, inbound
   SSH works, and the nginx vhosts (forgejo, it-tools) respond.

**Check:** positives pass, negatives time out, and the `counter drop`
rules show growing packet counts. The counters are kept permanently as an
ongoing signal of blocked egress attempts.

## Known effects

- The firewall backend switches to nftables on the next switch. During the
  switch there is a short window (seconds) where INPUT has no rules while
  the iptables rules are removed and the nftables ruleset loads — behind
  the UniFi gateway and invisible to established SSH sessions.
- Podman (rootful) stores pulled images under `/var/lib/containers`. The
  renovate image (~1.5 GiB) and the label's node image (~1 GiB) land there;
  the VM has 64 GiB.
- The runner service is DynamicUser with `StateDirectory`
  `/var/lib/forgejo-runner/codeberg` — reconstructable state.
- Job containers are unprivileged: capped at `--memory=2g --cpus=1`, no nix
  daemon access, no host bind mounts (`valid_volumes` empty by default),
  `docker_host: "-"` (the container socket is not shared into jobs), and
  egress restricted as described above. If a workflow with `services:` or
  the action cache ever misbehaves, the INPUT allow-list (DNS + port 32230)
  and the intra-job-network rule are the first places to look. This
  contrasts deliberately with the trusted GitHub runner pool on the same
  host.
- Outbound-only connectivity: the runner polls Codeberg; nothing needs to
  be opened in any firewall.

## Rollback

- Remove `codeberg-runner-on-srv-prod-6` from
  `modules/hosts/srv-prod-6/configuration.nix` and merge — comin switches
  the service off. That is the end of state-based rollback.
- Optionally deregister the runner on the Codeberg runner page and delete
  the sops key `forgejo-runner/token`.
- Idempotency: deleting the aspect twice is harmless (second run is a no-op
  merge); the Codeberg deregistration errors if the runner is already gone.

## Next steps (follow-up tasks)

- ✅ Renovate setup documentation:
  `modules/hosts/srv-prod-6/services/renovate.md` covers the workflow, the
  two repository secrets (`RENOVATE_TOKEN`, `GH_TOKEN`) and where they
  were generated, and the dedicated `britters-bot` account (Proton alias,
  commit attribution). Verify the token-scope details noted there against
  what was actually selected.
