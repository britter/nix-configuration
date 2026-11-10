# Self-hosted binary cache & push-based rollouts

**Status:** idea, not yet a plan. Written on 2026-11-10 after the
Stirling PDF Keycloak attempt
([`docs/plans/stirling-pdf-keycloak-sso.md`](../plans/stirling-pdf-keycloak-sso.md),
now abandoned) hit an architecture gap. When this direction firms up,
expand it into a proper plan document under `docs/plans/`.

## Problem

Deployment is pull-based: comin on each host polls `main`, builds the
host toplevel locally, and switches. Each host pays its own build cost,
and the only shared amortization is the official binary cache, which
serves free packages only. Two recent data points:

- srv-prod-2 sat on its 2026-11-04 generation for five days because its
  comin deployer was suspended. The catch-up switch to a fresh
  nixpkgs-unstable pin (renovate's lock file maintenance, #353) built
  around 350 derivations locally.
- the full `pkgs.stirling-pdf` (needed for login and SSO, see the
  abandoned plan) is `mit unfree`. cache.nixos.org does not carry it, so
  every deploy would rebuild it from source on every lock file bump.

## Sketch

- Backing store: Garage on srv-prod-3 (S3-compatible) already exists and
  is backed up.
- Cache server: attic vs harmonia vs nix-serve. attic has S3 support and
  a token model for pushes; needs evaluation against the others.
- Signing: one key for narinfo/signatures; hosts get the matching
  `trusted-public-keys`.
- Fill: jobs (probably the self-hosted GitHub runners, or a systemd
  timer on a builder host) run `nix build` for each host toplevel and
  `nix copy` / attic-push the closure into the lab cache, so hosts
  substitute instead of building.
- Rollout: a later, optional step. A build or push job targets hosts
  directly (`nixos-rebuild --target-host`, deploy-rs, or
  `nix copy` plus switch-to-configuration). comin stays during the
  transition; replacing it is on the table once that works for all
  hosts.

## What it would solve

- Unfree packages deployable at the cost of one build per `main` move
  instead of one build per host.
- Rollback closures retained in the cache.
- The same treatment for local packages under `packages/` and for the
  `nixpkgs-pr` input builds.

## Open questions

- attic vs harmonia vs nix-serve: features, maintenance status, and how
  painful the token model makes CI pushes.
- Where the cache signing keys live, and which hosts are trusted.
  Includes the per-host class policy for `nix.settings.substituters`
  and `trusted-public-keys`, and the ordering/priority semantics
  against cache.nixos.org.
- Build trigger policy: every push to `main`, every PR, or only when the
  old build differs? Gate on the existing self-hosted GitHub pool
  (`runs-on: [self-hosted, trusted]`)?
- Build all hosts on every merge, a representative set, or machines on
  demand?
- If rollout goes push-based: what replaces comin, and what breaks if
  comin stays? The suspended-deployer failure mode on srv-prod-2
  (2026-11-09) is one data point for replacing it.
- Storage and GC policy on the cache: retention for old generations vs
  disk headroom on the Garage host, and who prunes stale paths.
- Where build failures surface: the GitHub pipeline, or does a failed
  build block the affected host from switching until fixed?

## Consequences for related work

- Stirling PDF SSO stays parked. The free build has no login code at
  all (see the abandoned plan), so without the cache work the service
  keeps the auth-proxy shape (Calibre-Web style) whenever
  [`../plans/keycloak-sso-rollout.md`](../plans/keycloak-sso-rollout.md)
  resumes.
- Changing the deployment architecture touches incident response (which
  host fetched what), comin's retention and boot reports, and the
  branch protection story. The `tofu` pipelines' plan-on-PR model is
  probably unaffected. This doc stays shallow on all of these until the
  direction is chosen.
