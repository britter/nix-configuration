# Renovate workflow on the Codeberg runner

How the Renovate setup for
[`britter/nixpkgs-pr`](https://codeberg.org/britter/nixpkgs-pr) works and
what was configured by hand. The workflow is
`.forgejo/workflows/renovate.yaml` in that repository; it runs daily at
03:00 (plus manual `workflow_dispatch`) on the self-hosted runner on
`srv-prod-6` (see `codeberg-runner.nix` next to this file).

## Bot account

Renovate acts as the dedicated Codeberg account **`britters-bot`**, not as
my personal account:

- Registered with a dedicated Proton Mail alias,
  `benedikt.ritter+renovate-bot@proton.me`. That address is also the
  `RENOVATE_GIT_AUTHOR` in the workflow, so the commits and pull requests
  the action creates are attributed to the bot identity end to end
  (commit author, push, PR author), never to my personal account.
- Keeping the token on a dedicated account shrinks the blast radius: the
  token can only touch repositories that `britters-bot` has access to. If
  it ever leaks, my other repositories are not exposed.
- `britter` (repository owner) granted `britters-bot` access to
  `nixpkgs-pr` — and to that repository only, so it is the single
  repository the token can reach.

## Workflow secrets

Both secrets referenced by the workflow are repository-level secrets,
configured at <https://codeberg.org/britter/nixpkgs-pr/settings/actions/secrets>.
They exist only on Codeberg — they are never present on `srv-prod-6`, in
this repository, or in the runner's configuration.

- `RENOVATE_TOKEN` — a Codeberg access token of the `britters-bot` account
  (generated while logged in as `britters-bot` under Settings →
  Applications → Access Tokens). It needs repository read/write scope:
  Renovate uses it to clone, push update branches, and open PRs against
  `https://codeberg.org/api/v1` (`RENOVATE_ENDPOINT`).

  It must be a `britters-bot` token, not one from the personal account: a
  personal-account token could write to every repository the account can
  access, and renovate PRs would show up as authored by the personal
  account. If a personal token was created by mistake, revoke it
  (Settings → Applications in the personal account) after replacing the
  repository secret with a `britters-bot` token.
- `GH_TOKEN` — a GitHub token passed as `GITHUB_COM_TOKEN`. Renovate uses
  the GitHub API to read changelogs and source metadata for dependencies
  hosted on github.com; without it, API rate limits stall the run.
  Generated on <https://github.com/settings/tokens> as a fine-grained
  token with read-only access (public repositories are enough).

The runner's own registration token is a separate secret (sops
`forgejo-runner/token` on `srv-prod-6`) — it identifies the runner to
Forgejo, not the bot to the repository. See
`docs/plans/forgejo-runner-on-srv-prod-6.md` for the registration runbook.

## Operational notes

- The runner only picks up jobs labelled `runs-on: docker`; the workflow
  overrides the container image with a digest-pinned
  `ghcr.io/renovatebot/renovate:44` image. Bump the digest manually (or
  let Renovate's digest pinning PRs do it) — the runner pulls whatever the
  workflow names.
- Job containers are sandboxed and egress-restricted; see the trust-model
  section in `docs/homelab.md` for what a job can and cannot reach.
