# Migration plan: beszel hub srv-prod-1 → directions

Status: in progress (2026-10-27) — steps 1 and 2a–2d are done (the ✅
marks below). The cutover changes (code + sops move) sit staged on the
`beszel-on-directions` branch, not yet pushed. Remaining: commit and
open the cutover PR (do not merge before step 3), step 3 (move the
state), step 4 (merge), step 5 (retire the old state about a week
later). Status marks: ✅ done, ⏳ pending (same convention as the minIO
→ garage plan).

Steps for moving the beszel hub from srv-prod-1 to directions while
keeping every user, system, alert, and the whole metrics history —
without touching any agent. Two rollouts: a small PR takes the hub
down on srv-prod-1 first, then the cutover PR re-enables it on
directions and carries all the re-pointing and secret moves.

## Background

- The hub runs on srv-prod-1 (`modules/nixos/beszel-hub.nix`, imported by
  that host) and serves `https://beszel.srv-prod-1.ritter.family`; the
  public entry point `https://beszel.ritter.family` is proxied by
  directions (`modules/hosts/directions/services/https-proxy.nix`) to that
  address. The vhost routing therefore stays on directions untouched —
  the whole routing change is re-pointing that entry's upstream at the
  local hub.
- Six agents run on directions, srv-prod-1 … srv-prod-5 with
  `beszel-agent.nix`. All of them connect *to* the hub (token / WebSocket
  mode: `HUB_URL = https://beszel.ritter.family` + per-host
  `beszel/token` secret), the hub never dials them.
- `modules/nixos/beszel-agent.nix` hardcodes the hub's SSH public key
  (`KEY`) as pin; the matching private key lives in srv-prod-1's
  `secrets.yaml` (`beszel/hub-private-key`, plus unused-but-referenced
  `hub-public-key`) and is re-installed into the hub data dir on every hub
  start.

## Approach: raw copy of the hub state directory

The hub is PocketBase-backed: all state (user, systems with their agent
tokens, alert rules and contact points, settings, and the metrics history)
lives in `/var/lib/beszel-hub/` — mainly the `beszel_data/` subdirectory
(`beszel.db` & co.) plus `config.yml` and the SSH key. Answering the
original question: a plain copy of that directory is the way. Beszel has no
export that does this job — the UI's settings export only covers app
settings (no systems, no history, no tokens), and a UI backup zip is just a
wrapper around the same bytes we can rsync directly. Because the hub's
data is one small SQLite-like store, the whole migration amounts to: take
the old hub down through its own rollout, copy the quiescent directory,
move the sops secrets and bring the hub up on directions, then delete the
old state.

Nothing else needs to migrate:

- `config.yml` is declarative: preStart reinstalls it on every start from
  the flake (`monitoredHosts` already lists all six hosts, and srv-prod-1
  keeps its agent).
- `beszel_data/id_ed25519` is reinstalled from sops on every start, so the
  keypair survives as long as the sops entries move with the state copy.
- Agents: `beszel/token` (in each host's own secrets), `KEY`, and `HUB_URL`
  all stay valid: the tokens come from the copied database, the keypair
  comes from the moved sops secret, and `https://beszel.ritter.family` will
  be served by directions locally after the move.
- DNS: `beszel.ritter.family` already resolves to directions via the
  `*.ritter.family` record in `tofu/network/dns.tf`. No change.
- Firewall: directions (192.168.30.6) is in the same Servers network as the
  hub, the proxy, and every agent — intra-VLAN, so no tofu change; the
  `management_to_servers_beszel` policy keeps its meaning.
- Ports: the hub binds 127.0.0.1:8090 on directions; that port is free.
- Monitoring: the gatus check (`beszel.ritter.family/api/health`) and the
  homepage tile are host-agnostic. In-hub alert definitions survive the
  copy.

## Cutover runbook

Order matters because comin switches servers on their own as soon as
`main` moves. This sequence keeps every switch deterministic: phase 1
stops the hub via its own rollout before anything else changes, and the
cutover PR's srv-prod-1 side is inert (it only removes secrets the hub no
longer consumes), so no comin pinning is needed. Work the list top to
bottom.

### ✅ 1. Phase-1 PR: take the hub off srv-prod-1

An aspect is enabled by import, so "disable beszel in the beszel module"
means dropping the import. The `beszel-hub` aspect itself is not touched,
which makes the re-enable in the cutover PR a one-line import on
directions. Everything except the hub survives; srv-prod-1 keeps its
agent:

```diff
@@ modules/hosts/srv-prod-1/configuration.nix @@
       system-server
       proxmox-vm
       tailscale-server
-      beszel-hub
       beszel-agent
       (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
```

This is the whole PR — one line removed, no other file touched. The
hub's sops entries stay in srv-prod-1's secrets file for now; the
cutover PR removes them (until then they are simply unconsumed).

Ship it the normal way: `nix fmt`, `nix flake check`, PR, CI green,
merge. comin switches srv-prod-1 within a couple of minutes. Then check
the phase gate — run them from framework-13, any host that reaches
`root@<host>.ritter.family` over ssh works as well:

```bash
ssh root@srv-prod-1.ritter.family systemctl status beszel-hub
# expected: 'Unit beszel-hub.service could not be found.'

ssh root@srv-prod-1.ritter.family systemctl is-active beszel-agent
# expected: 'active' — srv-prod-1 stays a monitored host

ssh root@srv-prod-1.ritter.family \
  ssh-keygen -y -f /var/lib/beszel-hub/beszel_data/id_ed25519
# expected: the public key that is hardcoded in beszel-agent.nix
```

Do not move on until all three pass. From that moment until the cutover
merges, `beszel.ritter.family` no longer serves the hub (its upstream
vhost no longer exists): agents cannot connect, and URL-based checks —
gatus included — are not meaningful there, because srv-prod-1's default
vhost handling answers instead. This is the deliberate downtime window —
prepare the cutover PR while phase 1 rolls out and don't let it sit.

### ⏳ 2. Phase-2 (cutover) PR: move the hub to directions

Compose all four changes on a branch and open the PR as one. Merge
happens in step 4, after the state move — comin would otherwise deploy a
hub whose secrets file exists but whose state directory is empty.

#### ✅ 2a. Re-enable the hub aspect, now on directions

```diff
@@ modules/hosts/directions/configuration.nix @@
       system-server
       adguard
       beszel-agent
+      beszel-hub
       gatus
       homepage
```

The aspect brings the hub service, the sops wiring for its secrets, and
the preStart key/config install. As on every host it also registers its
derived vhost `beszel.directions.ritter.family` targeting the local hub
— a spare name that is inert on the LAN (`*.ritter.family` matches one
label only, so nothing answers it) at the cost of one extra DNS-01
certificate.

#### ✅ 2b. Re-point the upstream of the beszel vhost

The entry in `modules/hosts/directions/services/https-proxy.nix` keeps
its fqdn and its certificate; only the upstream changes, from the
srv-prod-1 chain to the hub on the same host:

```diff
@@ modules/hosts/directions/services/https-proxy.nix @@
         configurations = [
           {
             fqdn = "beszel.ritter.family";
-            target = "https://beszel.srv-prod-1.ritter.family";
+            target = "http://localhost:${toString config.services.beszel.hub.port}";
             proxyWebsockets = true;
           }
```

`config.services.beszel.hub.port` is the nixpkgs option (default 8090;
declared by the nixpkgs hub module the aspect enables, so it resolves
once `beszel-hub` is imported on directions in 2a), and `localhost` as
an upstream is the same pattern the hub aspect and the adguard entry in
this file already use. The intermediate name
`beszel.srv-prod-1.ritter.family` disappears with the old hub and
nothing references it afterwards.

#### ✅ 2c. Move the hub secrets between the host sops files

Run on framework-13, which holds the age key for both files. `sops set`
has no export/import mode, so the move pipes the decrypted value from
the source `--extract` straight into `set` on the target — no manual
copying, and no plaintext on disk, in argv, or in shell history (values
only flow through pipes at execution time). Use bash for these steps;
the verify loop relies on process substitution:

```bash
# 1. copy into directions (idempotent — safe to re-run)
for key in hub-private-key hub-public-key hub-admin-password; do
  sops -d --extract "[\"beszel\"][\"$key\"]" modules/hosts/srv-prod-1/secrets.yaml \
    | jq -Rs . \
    | sops set --value-stdin modules/hosts/directions/secrets.yaml \
        "[\"beszel\"][\"$key\"]" >/dev/null
done

# 2. verify each transfer byte-for-byte, before deleting anything
for key in hub-private-key hub-public-key hub-admin-password; do
  diff <(sops -d --extract "[\"beszel\"][\"$key\"]" modules/hosts/srv-prod-1/secrets.yaml) \
       <(sops -d --extract "[\"beszel\"][\"$key\"]" modules/hosts/directions/secrets.yaml)
done

# 3. remove the source entries (beszel/token stays — srv-prod-1 keeps its agent)
for key in hub-private-key hub-public-key hub-admin-password; do
  sops unset modules/hosts/srv-prod-1/secrets.yaml "[\"beszel\"][\"$key\"]"
done
```

The `jq -Rs .` hop is required, not cosmetic: `sops set` expects a JSON
encoded value and rejects raw bytes like the multiline SSH key. Quoting
every value as a JSON string also pins them to string type (verified on
a throwaway config — an admin password that looks numeric is stored as
a string, not an int). Each `set`/`unset` decrypts, rewrites, and
re-encrypts a single file in place and preserves its existing
recipients. `sops set` prints the whole updated file (hence
`>/dev/null`); `unset` is quiet. After the delete loop has run,
re-running it errors — only the copy loop is idempotent.

After the loop the PR diff looks like this (ciphertexts rendered as
placeholders — the actual blobs are re-encrypted for each file's
recipients by the commands above, so never copy encrypted values by
hand; the `sops:` metadata block also updates `lastmodified` and `mac`
in both files):

```diff
@@ modules/hosts/srv-prod-1/secrets.yaml @@
 beszel:
-    hub-public-key: ENC[AES256_GCM,...]
-    hub-private-key: ENC[AES256_GCM,...]
-    hub-admin-password: ENC[AES256_GCM,...]
     token: ENC[AES256_GCM,...]
```

```diff
@@ modules/hosts/directions/secrets.yaml @@
 beszel:
     token: ENC[AES256_GCM,...]
+    hub-private-key: ENC[AES256_GCM,...]
+    hub-public-key: ENC[AES256_GCM,...]
+    hub-admin-password: ENC[AES256_GCM,...]
```

No `.sops.yaml` change needed: directions' file is already encrypted to
framework-13 + the directions age key. No rotation either — the point
of the state copy is that every token and credential stays identical.

#### ✅ 2d. Fix the stale agent comment

```diff
@@ modules/nixos/beszel-agent.nix @@
     services.beszel.agent = {
       enable = true;
       openFirewall = true;
       environment = {
         HUB_URL = "https://beszel.ritter.family";
         PORT = "45876";
-        # Bezel Hub's SSH public key, which is stored in /var/lib/beszel-hub/id_ed25519.pub.
-        # For Beszel on srv-prod-1, the value is stored in modules/hosts/srv-prod-1/secrets.yaml
+        # Beszel Hub's SSH public key, installed as /var/lib/beszel-hub/id_ed25519.pub
+        # on the hub host (directions). The value is stored in modules/hosts/directions/secrets.yaml
         KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDM4/5m4XKP1a+BT7nVqmo4NaHJIk26rS+NbemzQw6y5 bene@framework-13";
         TOKEN_FILE = config.sops.secrets."beszel/token".path;
       };
     };
```

The `Bezel` typo goes with the stale path since the same lines are being
rewritten anyway.

Wrap the phase-2 PR up:

```bash
nix fmt
nix flake check
```

PR as usual, let CI build everything. Do not merge yet — the state
goes first.

### ⏳ 3. Move the state (PR open, not merged)

The source directory has been quiescent since step 1 — no stop/start
dance needed, and because the source database froze when phase 1
stopped the hub, there are no deltas to chase:

```bash
rsync -a --info=progress2 \
  root@srv-prod-1.ritter.family:/var/lib/beszel-hub/ \
  root@directions.ritter.family:/var/lib/beszel-hub/

# sanity check on the destination
ssh root@directions.ritter.family ls /var/lib/beszel-hub /var/lib/beszel-hub/beszel_data
```

The files arrive with srv-prod-1's numeric uids; that is fine — when
the hub first starts on directions, systemd re-assigns the state tree
to the unit's user, the same mechanism that already carries srv-prod-1
through reboots. Watch the first start in the journal anyway.

### ⏳ 4. Merge the cutover PR

Merge once CI is green. That is the trigger; directions switches within
a couple of minutes:

```bash
# on directions
journalctl -fu comin
```

What to expect in that switch: the hub starts with the seeded database,
nginx re-points `beszel.ritter.family` at the local hub, and the ACME
machinery issues the spare-vhost certificate. The public URL starts
serving again and the agents reconnect on their own.

srv-prod-1's switch lands whenever it lands — its hub is already gone,
and the only change here is dropping three unconsumed sops entries, so
the order no longer matters.

End of the phase: check the boundary. The hub must be up on directions,
absent on srv-prod-1, and the public entry must serve the hub's own
health payload (static JSON today, so local and public responses
compare byte-for-byte; if a future hub adds volatile fields, compare
the payload shape instead). Do not move on until these pass:

```bash
ssh root@directions.ritter.family systemctl is-active beszel-hub
# expected: 'active'

ssh root@directions.ritter.family \
  "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8090/api/health"
# expected: '200' — the hub serves on 127.0.0.1:8090

ssh root@srv-prod-1.ritter.family systemctl status beszel-hub
# expected: still 'Unit beszel-hub.service could not be found.'

ssh root@directions.ritter.family \
  "curl -s http://127.0.0.1:8090/api/health" > /tmp/hub-local.json
curl -s https://beszel.ritter.family/api/health > /tmp/hub-public.json
diff /tmp/hub-local.json /tmp/hub-public.json \
  && echo 'public entry serves the local hub'
# expected: the echo line, no diff output
```

Then check the system content in the hub UI (admin password unchanged):
all six systems — directions, srv-prod-1 … srv-prod-5 — show a connected
state with fresh timestamps, the alert rules and contact points from
before the move are intact, and the history graphs end at the downtime
window and resume with live data (the gap is expected, see Known
effects). An optional probe for the reconnect path:

```bash
ssh root@srv-prod-2.ritter.family systemctl restart beszel-agent
# expected: the srv-prod-2 row recovers within seconds
```

gatus must come back healthy too:

```bash
curl -s https://gatus.ritter.family/api/endpoints/statuses \
  | jq -r '.[] | select(.name == "Beszel") | "\(.name): \(.status)"'
# expected: 'Beszel: healthy'
```

(The API is public in this gatus setup; if a future gatus version names
the JSON fields differently, read the raw response instead. Nothing
else points at `beszel.srv-prod-1.ritter.family`, and the other services
proxied by directions are outside this migration — spot-check one if
you like. If any gate above fails, fall back to the Rollback section
instead of proceeding.)

### ⏳ 5. Retire the leftover state on srv-prod-1 (about a week later)

Once the new hub has run through a soak period and the rollback window
can close, delete the old state. Before the delete, re-run the step-4
gate commands once more — they must still pass, because this step ends
the state-based rollback: reverting the PRs afterwards would give a
running but empty hub.

```bash
ssh root@srv-prod-1.ritter.family rm -rf /var/lib/beszel-hub
```

The hub's sops entries were removed from srv-prod-1's secrets file as
part of the cutover PR, so nothing configuration-related remains there.

## Known effects and their limits

- Downtime window (deliberate): the hub is offline from the phase-1
  switch until the cutover switch. Agents keep running and reconnect on
  their own afterwards. During the window `beszel.ritter.family`
  answers from srv-prod-1's default vhost handling instead of the hub,
  so URL-based checks — gatus included — are not meaningful there and
  gatus may even stay green for the wrong reason; the step-1 gate
  commands are the reliable signal. Keep
  the window short by having the cutover PR ready.
- Metrics gap: history recorded during the downtime window is lost —
  the agents do not buffer history and the frozen srv-prod-1 database
  sees none of it.
- Certificate churn: the `beszel.ritter.family` cert on directions is
  reused unchanged. The spare derived vhost registered by the cutover
  PR (`beszel.directions.ritter.family`) triggers one new DNS-01
  certificate; the ACME units coordinate this around the running nginx.
- Grafana: the `grafana.ritter.family` proxy entry points at
  `grafana.srv-prod-1.ritter.family`, which nothing in this repo declares —
  it predates/bypasses the flake and needs its own look. It is independent
  of the hub aspect and unaffected by this migration either way.

## Rollback

- Before the cutover PR merges: abort it, then revert the phase-1 PR.
  comin puts the hub back on srv-prod-1 with its intact, untouched state
  directory; the seeded copy on directions is then just garbage to
  delete (`rm -rf /var/lib/beszel-hub` there).
- After the cutover PR merges: revert both PRs (one revert PR that
  undoes the two changes is enough). comin redeploys the previous
  generation on both hosts: srv-prod-1's hub comes back with its intact
  state and the directions proxy serves it through the chain again;
  agents follow the public name without a manual step. Delete
  directions' stale copy first so the old hub's files are the only ones
  around.

## Cleanup / follow-ups

- ⏳ When done, move this plan to
  `docs/plans/archive/<date>-beszel-hub-move-to-directions.md` per
  AGENTS.md.
- No tofu changes: DNS already routes `beszel.ritter.family` to directions
  (the public vhost's name), and the firewall policy maps cleanly onto the
  new layout.
- Optional: if the hub aspect's derived spare vhost
  (`beszel.directions.ritter.family`) and its certificate ever bother you,
  make the aspect's proxy registration skippable. Nothing in this
  migration depends on it.
- Separate observation, unrelated to this move: the directions proxy entry
  for `grafana.ritter.family` targets a name that no repo-configured host
  serves. Worth a look on its own.
