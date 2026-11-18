# Incident: Network 11 upgrade silently invalidated the tofu network state — 2026-11-17

**Status:** root cause identified 2026-11-18; remediation (DNS record re-import +
duplicate policy cleanup) pending — the exact commands are in the Resolution section.

A renovate lock-file maintenance PR
([#370](https://github.com/britter/nix-configuration/pull/370), merged 2026-11-17
12:24 UTC) reported `tofu/network` changes it could not possibly have made — a plan
of **32 to add** (15 `unifi_dns_record`, 17 `unifi_firewall_policy`) on a PR that only
touched `flake.lock` and `packages/testlens-cli/deps.json`. The merge apply then
failed: all 17 firewall policies were re-created on the controller (duplicating them),
and all 15 DNS record creates were rejected with
`api.err.StaticDnsRecordAlreadyExists`, leaving the `OpenTofu Network` pipeline on
main red.

## Symptoms

- PR #370 CI plan (2026-11-16 00:30): `Plan: 32 to add, 0 to change, 0 to destroy`
  for `tofu/network`; the other four tofu pipelines reported no changes.
- Merge apply (2026-11-17 12:25 UTC): 17 `unifi_firewall_policy` creates succeeded
  (new UUID ids), 15 `unifi_dns_record` creates failed with
  `StaticDnsRecordAlreadyExists (400)` against
  `/proxy/network/v2/api/site/default/static-dns`.
- A local `tofu plan` on 2026-11-18 still wants to create the 15 DNS records; the
  firewall policies now plan clean.

## Root cause

A UniFi controller upgrade to **Network 11.0.99** between 2026-11-10 and 2026-11-16
— not the PR, and not the provider (0.65.0, unchanged since 2026-11-04).

Network 11 re-keys existing objects from 24-hex MongoDB ids to UUIDs. The provider
matches `unifi_dns_record` and `unifi_firewall_policy` by strict id on refresh, so
every one of those resources 404'd and tofu concluded they had all been deleted:

- 2026-11-10 apply: `unifi_firewall_policy.homeassistant_to_directions` created with
  Mongo-style id `6af2f737428b4df6b7a1a3f1`.
- 2026-11-16 plan: same resource refreshes "not found"; re-created on 2026-11-17 as
  UUID `9c4ade8a-4504-497f-b532-e049670d275a`.

Applying that plan re-created all 17 policies as second copies. The DNS creates
failed because the originals still exist (the controller enforces key uniqueness on
create), so DNS records ended up deleted from state while still live on the
controller. The state *was* persisted for the 17 policies despite the failed apply,
so state and controller agree on those — but each policy now exists twice.

`unifi_network`, `unifi_client` and the firewall zone data sources were unaffected:
the provider re-matches those by name/MAC during refresh and silently adopted the new
UUID ids, which is why no plan ever mentioned them. All 32 planned resources were
v2-API resources; everything on the v1 API refreshed fine.

Timeline (UTC):

- 2026-11-10 10:51 — last good apply (`network: open network route from smart home
  VLAN to servers VLAN`), controller still returns Mongo ids.
- between 11-10 and 11-16 — controller upgraded to Network 11.0.99.
- 2026-11-16 00:30 — PR #370 CI plans 32 adds (first sighting of the drift).
- 2026-11-17 12:24 — PR #370 merges; 12:25 apply duplicates the 17 policies and
  fails on the 15 DNS records.
- 2026-11-18 — root cause confirmed against the live controller with `unifly` and
  the raw v2 API.

This is a documented failure mode:
[ubiquiti-community/terraform-provider-unifi#716](https://github.com/ubiquiti-community/terraform-provider-unifi/issues/716)
("upgrading to Network 11 can duplicate firewall zones, NAT rules and AP groups",
filed 2026-11-11 against exactly this controller version) and
[#715](https://github.com/ubiquiti-community/terraform-provider-unifi/issues/715)
(import by UUID fails for name-importable resources — does *not* affect
`unifi_dns_record`/`unifi_firewall_policy`, verified in the v0.65.0 source).

## Verification

Read-only checks that confirmed the diagnosis (controller at `unifi.ritter.family`):

```sh
# 15 records with UUID ids; none of them in tofu state:
unifly api 'v2/api/site/default/static-dns' | jq 'length'

# 138 policies; each managed name appears twice (pre-upgrade original with low
# index and high hit counter, state-tracked copy created 2026-11-17):
unifly api 'v2/api/site/default/firewall-policies' | jq 'length'
unifly api 'v2/api/site/default/firewall-policies' \
  | jq -r '.[] | select(.name == "Allow SSH from Trusted") | "\(.["_id"]) index=\(.index) hits=\(.hits)"'
```

Caveat discovered during verification: unifly's Integration API and the provider's
v2 session API use **different id namespaces** for the same objects. Only v2 ids are
valid for `tofu import`.

## Resolution

*Pending as of 2026-11-18. Detailed working notes:
`.my-plans/370-tofu-network-drift/runbook.md` (untracked).*

1. **Re-import the 15 DNS records** into state by their current v2 ids
   (state-only change, no controller writes). Example for one record; the full
   id↔record mapping is in the runbook:

   ```sh
   cd tofu/network
   tofu import unifi_dns_record.srv_prod_2 d5072d8b-d692-413b-9739-956c6d6c1a85
   ```

   Afterwards `tofu plan` must show no changes for DNS records.

2. **Delete the 17 orphaned pre-upgrade firewall policies** from the controller
   (each duplicated name: keep the state-tracked copy, delete the original). Safe
   because only identical ALLOW rules sit between the two copies' indexes. Via the
   UniFi UI (Settings → Security → Firewall Policies, delete the copy with the high
   hit counter) or by v2 id:

   ```sh
   for id in \
     ccd68c9e-5b97-42b3-ab6c-a5ee3d9a8d98 \
     d6486212-3e74-47db-8b27-23f92f3fa50a \
     7a17d669-d728-401d-b830-6dd74b371ab2 \
     f43f5824-441a-4eb4-8cb3-941a30b415d1 \
     6e036260-58b2-4ce3-8465-26569ea9d1d3 \
     ae2466fc-1e76-414f-9b74-28968d8f4cb4 \
     836d6c54-b341-4f8b-a8a7-63f746f382fd \
     2ca7b3db-461e-439d-aa11-0a083e667323 \
     e5a96731-48ea-4dfd-88f7-bbc9150976b8 \
     97ce8e1f-3b0d-45c0-afb7-7ea6e2cd861e \
     4a82cd41-1aeb-4960-88b6-f9b3240c51f5 \
     42f5b8d0-e06f-424f-bd0d-f82c23cbf3f4 \
     c56d2fdf-4995-4858-b7c7-2ec2a648be54 \
     22c11dcd-dd90-482e-afae-3e5193e177ac \
     e112052b-6d94-4b68-b832-30f13cfeee88 \
     3e49f542-9e68-4f4f-9641-3c597a27aff2 \
     3cf07a80-890b-4f53-9585-d8d3e674994d ; do
     unifly api -m delete "v2/api/site/default/firewall-policies/$id"
   done
   ```

   The controller should cascade-delete each orphan's auto-generated "(Return)"
   twin; policy count drops 138 → 104. Alternative preserving the originals'
   ordering and hit counters (state rm + import, per #716) is described in the
   runbook; end state is identical.

3. **Verify:** `tofu plan` reports no changes; the next push run of
   `OpenTofu Network` on main is green; subsequent renovate PRs report
   "No changes" again.

No provider upgrade is needed — 0.65.0 works against the migrated controller once
state is reconciled.

## Follow-ups

- **Add a drift guard to `.github/workflows/_tofu.yaml`**: fail the plan step when
  the plan's `resource_drift` contains `delete` actions. That would have stopped
  this at PR time on 2026-11-16 instead of reaching apply on merge (suggested in
  #716 as well).
- **Future controller upgrades**: expect v2-API resources (`unifi_dns_record`,
  `unifi_firewall_policy`, `unifi_firewall_zone`, `unifi_nat`, `unifi_ap_group`) to
  lose their ids on major Network upgrades. Before merging anything afterwards,
  check whether the plan contains unexpected creates; reconcile by import, not by
  apply.
- Watch upstream #715 — once a release accepts UUID ids everywhere, import stops
  depending on id-format quirks.
- PR #370 and future renovate lock-file PRs are innocent; no renovate changes are
  needed.
