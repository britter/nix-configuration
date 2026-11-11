# Security hardening

**Status:** idea, not yet a plan. Written on 2026-11-11 from loose notes and
a ChatGPT discussion about account security. This is deliberately broader
than one plan: it covers credentials, SSH, network segmentation, egress,
disk encryption and Secure Boot, and the NixOS baseline, and will likely
split into several plan documents under `docs/plans/` once the individual
directions firm up.

## Problem

The lab has grown a decent identity layer (Keycloak SSO rollout, tofu-managed
clients, documented break-glass procedures), but the layers underneath are a
mix of defaults and one-offs: password-based access is still possible on some
services, SSH keys are ordinary on-disk private keys, hosts can reach the
internet unrestricted, disks are unencrypted, and there is no documented
threat model or per-layer baseline. The recurring tension is security vs. comfort: the most secure
option is usually the one that adds friction to everyday admin work, and the
lab is a single-admin household where an over-hardened setup just gets
routed around.

## Areas

### Network access and segmentation (management VLAN)

The UniFi network is segmented with default-deny inter-VLAN policy
(`tofu/network/firewall_policies.tf`, e.g. the Smart Home → directions
rule). But admin access into the management VLAN (UniFi controller,
Proxmox, switches, access points) works through direct routes from the
regular LAN.

Idea: manage things in the management VLAN **without a direct network
route** from the laptop's normal network. Options:

- a WireGuard endpoint on a small entry host, so the laptop reaches the
  management VLAN only with the tunnel up;
- a jump host in the management VLAN used for UI/SSH access;
- actually switching the laptop into the management VLAN (dynamic VLAN /
  port change) when administering — most secure separation, most friction;
- keeping direct routes but tightening which source may reach which
  management interface.

This is the clearest security-vs-comfort tension in the whole document:
switching VLANs is annoying enough that it will be skipped exactly when it
matters. The access model has to be near-zero-friction or it is fiction.

### Egress control (servers VLAN first, then management and smart home)

Inter-VLAN traffic is default-deny, but **egress to the internet is
unrestricted** for nearly every host. There is precedent for host-local
enforcement: the `container-egress` nftables table on srv-prod-6 limits
Forgejo runner containers to internet egress plus DNS and one pinned port,
precisely because the UniFi gateway cannot see the per-container traffic
behind NAT (`docs/homelab.md`, Forgejo runner section).

Idea: default-deny egress per host (or per VLAN), with explicit allowlists
for what each host actually needs — DNS, NTP, package/cache hosts, backup
targets, Garage/S3, Keycloak, SMTP. Servers VLAN first; management and
smart home follow. Decisions to make: enforcement point (UniFi gateway
policy vs. host-local nftables, given the NAT argument above) and how
missing rules surface (ideally gatus alerts, not silent breakage two weeks
later).

### Account security (Vaultwarden, passkeys, YubiKeys)

Vaultwarden is already self-hosted (`modules/nixos/vaultwarden.nix`, on
srv-prod-2, accessed via rbw — see the 2026-11-04 rbw incident for the
access-token story). The discussion converged on combining Vaultwarden,
Argon2id, and YubiKeys instead of relying on a single mechanism:

- **Vaultwarden + Argon2id:** long unique master passphrase (5–7 random
  words), Argon2id KDF configured client-side (Settings → Security → Keys),
  parameters chosen so the weakest daily device stays tolerable; encrypted,
  independent vault backups; recovery codes stored outside Vaultwarden.
- **Two YubiKeys** (primary + backup, stored separately), registered on all
  critical accounts: primary email, the password manager itself, domain
  registrar, hosting/cloud infrastructure, financial accounts where
  supported — as hardware-bound FIDO2 passkeys.
- The split of responsibilities: Vaultwarden carries convenience and
  cross-device sync for everyday passwords and passkeys; YubiKeys isolate
  the keys that must not be stealable; Argon2id raises the cost of offline
  guessing if the encrypted vault leaks.

### SSH hardening

Replace conventional on-disk private keys with FIDO2-backed resident keys:

    ssh-keygen -t ed25519-sk -O resident -O verify-required -C "homelab-admin"

- private key material stays on the YubiKey; PIN + touch per use;
- the same public key registers on every server; resident credentials are
  recoverable on another workstation with `ssh-keygen -K`;
- register **both** YubiKeys on every server.

Server-side: disable password authentication, disable direct root login,
use an individual admin account, restrict sshd to the management VLAN or
VPN, avoid agent forwarding, and keep console-based (Proxmox/hypervisor)
recovery access as break-glass. An SSH certificate authority with
short-lived certificates is probably overkill for a single admin today;
revisit if the number of principals grows.

### OS hardening (NixOS level)

A declarative per-host baseline, roughly:

- sshd settings declaratively (the SSH items above, per host class);
- a host nftables firewall module as the default, even where the gateway
  also filters;
- least privilege: audit `nix.settings.trusted-users` — the GitHub runners
  are already documented as root-equivalent via the nix daemon
  (`docs/homelab.md`, residual risk) — plus the comin deployer identity and
  sops age key placement per host;
- systemd unit sandboxing (hardening options) for self-hosted services;
- sudo/policykit policy, unattended maintenance, and sysctl/kernel knobs
  where they are worth the churn;
- a per-host inventory of exposed ports and capabilities (gatus/homepage
  config could double as the source of truth).

### Disk encryption and secure boot

Current state: only framework-13 (the laptop) is disk-encrypted; TrueNAS,
the PVE hypervisors, and all NixOS servers run on plaintext disks. The
threat model is mostly physical: a stolen disk or a decommissioned drive
that leaves the house (RMA, sale, e-waste) should not carry readable data.

The layers differ, and so do the options:

- **TrueNAS:** ZFS dataset (or pool) encryption is a settings change, no
  reprovisioning. Question is what the encryption root is bound to — a
  passphrase typed at boot defeats unattended reboots; a keyfile on the
  same machine is decoration.
- **PVE hypervisors:** LUKS on the host vs. LUKS in each guest. Host LUKS
  protects everything (including VM disks and hypervisor config) but needs
  the key at every hypervisor boot; per-VM LUKS is finer-grained but easy
  to forget on new VMs and protects nothing about the PVE host itself.
- **NixOS servers:** LUKS via the NixOS installer/`disko`, which means
  reprovisioning — this only folds into host reinstalls, never as a live
  change.

The cross-cutting problem is the **unattended restart**: how does a
headless server get its LUKS key at 3 am? Options, roughly in order of
trust assumption:

- passphrase typed at the console — attended reboots only, unacceptable as
  the default for servers;
- SSH (dropbear) in the initrd, so the passphrase is typed remotely once
  per boot — still manual, but works headless;
- YubiKey-backed unlock (FIDO2 `systemd-cryptenroll`), same YubiKeys as the
  account/SSH story above;
- TPM-sealed keys (bound to PCR values, i.e. only the unmodified OS on that
  machine unlocks) — fully unattended, and the theft case is reduced to
  "attacker with the whole running machine", which is the same trust level
  as an unencrypted running host anyway;
- network-bound encryption (Tang/Clevis) — unattended while the lab network
  is present, locked when a disk is taken elsewhere; extra service to run.

framework-13 needs the same decision (passphrase-only today vs. TPM +
YubiKey enrollment under systemd-cryptenroll).

Related: **Secure Boot is off on every device.** For the NixOS hosts,
[lanzaboote](https://github.com/nix-community/lanzaboote) (nix-community)
is the established way to enable it — it signs the UKI/stub with your own
keys, which pairs naturally with TPM-sealed disk encryption (the PCR state
that unseals the key is only meaningful if the boot chain is verified).
The PVE hosts would need the Debian-side manual key enrollment; TrueNAS
SCALE does not support Secure Boot. Whether Secure Boot matters on a
single-admin homelab (vs. just on the mobile framework-13) is part of the
open questions.

## Sketch of priorities

Adapted from the account-security discussion, with the network items
interleaved:

1. Strengthen the Vaultwarden master passphrase, configure Argon2id.
2. Obtain two YubiKeys; protect critical online accounts with FIDO2.
3. Switch SSH to YubiKey-backed keys; harden sshd on all servers.
4. Establish independent recovery (vault backups, recovery codes, break-glass
   console access) — tested, not just documented.
5. Pick and implement the management-VLAN access model.
6. Egress control on the servers VLAN.
7. NixOS hardening baseline, rolled out per host class.
8. Disk encryption and Secure Boot, folded into host reinstalls and the
   TrueNAS/PVE settings changes.

## Open questions

- Management-VLAN access model: WireGuard entry point vs. jump host vs.
  VLAN switching on the laptop — and what the break-glass path is when the
  entry point itself is unreachable?
- Egress enforcement point: UniFi gateway policies vs. host-local nftables
  (the NAT argument from the Forgejo runner setup), and how rule omissions
  get noticed (gatus checks per service?).
- How to allowlist egress without breaking auto-updates, Renovate, backups,
  and monitoring — which hosts actually need the internet?
- YubiKey logistics: which models, and the recovery story for a lost *or
  both-lost* scenario.
- FIDO2 SSH keys vs. automation: pull-based comin and any non-interactive
  jobs need a key story that doesn't require touch — separate plain keys
  for automation, restricted by source address?
- Vault backups: where, how encrypted, and how often restore is actually
  tested.
- Argon2id parameters that stay acceptable on the slowest daily device.
- NixOS baseline: which hardening options earn their keep per host class,
  and how to roll out without a flag day.
- LUKS unlock strategy per host class: initrd SSH vs. YubiKey vs. TPM
  sealing vs. Tang — and does one strategy cover all servers, or do the
  hypervisors and guests differ? What actually reboots unattended (power
  outage recovery) and what may wait for a human?
- PVE: host-level LUKS or per-VM LUKS — or both (hypervisor LUKS as the
  outer layer, guests encrypt the data that matters)?
- Secure Boot via lanzaboote on the NixOS hosts: worth the enrolment and
  signing workflow for a single-admin lab, or only for framework-13? How
  does the signing key live in sops, and what breaks on a nixpkgs bump?
- TrueNAS ZFS encryption: dataset vs. pool level, and what the key is
  bound to so it survives reboots but not a stolen drive.

## Consequences for related work

- **Deployment** (comin, and the
  [`self-hosted-binary-cache.md`](self-hosted-binary-cache.md) idea): SSH
  access changes and any push-based rollout interact directly; egress rules
  must cover a lab cache if that is built.
- **Keycloak SSO rollout** ([`../plans/keycloak-sso-rollout.md`](../plans/keycloak-sso-rollout.md)):
  a WebAuthn/2FA policy for the `homelab` realm belongs to the account
  security area and should be decided together with the YubiKey work.
- **tofu/network**: management access and egress changes live in
  `firewall_policies.tf` and friends; the UniFi's per-container filtering
  limits are a known constraint.
- **docs/homelab.md**: whatever break-glass and recovery procedures come out
  of this must be reflected there, same as the Proxmox and Beszel entries.
- **Backups and incident docs**: encrypted-at-rest hosts still send
  plaintext (or client-side-encrypted) data to TrueNAS and srv-offsite-1;
  disk encryption decisions on the storage side (TrueNAS) change what the
  backups protect against. Reprovisioning for LUKS touches the bootstrap
  flow (`docs/bootstrap.md`).
