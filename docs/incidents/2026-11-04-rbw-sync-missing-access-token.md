# Incident: rbw sync fails with `missing field 'access_token'` — 2026-11-04

`rbw sync` against the self-hosted Vaultwarden instance failed with:

```
rbw sync: failed to sync database from server: failed to parse JSON:
missing field `access_token` at line 1 column 25
```

Unlocking the locally cached vault kept working, so the problem only
showed up when talking to the server.

## Root cause

Not a Vaultwarden problem. rbw stores a refresh token locally and uses it
to fetch a fresh access token on sync. When the server rejects that
refresh token (expired or revoked), it answers with an error JSON body
that has no `access_token` field. rbw's `exchange_refresh_token` does
not check the HTTP status code before deserializing the response
(doy/rbw#342), so the real message — "your refresh token is invalid,
log in again" — surfaces as a serde parse error. The `column 25` is
just the length of the server's error body, nothing more.

This bug has been open since 2020 (doy/rbw#32) and hits both
vault.bitwarden.com and Vaultwarden.

## Resolution

```sh
rbw stop-agent
rbw purge
rbw login
rbw sync
```

`rbw purge` clears the cached vault and tokens but keeps
`~/.config/rbw/config.json`, so the server URL and email survive.
`rbw login` asks for the master password (and 2FA if configured) and
`rbw sync` re-downloads everything.

## Follow-ups

- If a similar parse error appears again right after a purge (for
  example `missing field 'Kdf'`), also kill any still-running
  `rbw-agent` holding old state before logging in again.
- Upstream fix is proposed in doy/rbw#342; once rbw checks the status
  code there, this will report as an auth error instead.
