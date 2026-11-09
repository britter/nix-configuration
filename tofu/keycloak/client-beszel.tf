# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "beszel" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "beszel"
  name      = "Beszel"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # PocketBase's OIDC provider config has a "Support PKCE" checkbox and
  # implements only S256; the hub is configured to tick it (see the
  # Beszel plan's Part B).
  pkce_code_challenge_method = "S256"

  # Operator-generated and seeded into sops (tofu/keycloak/secrets.json).
  # The hub keeps its own copy in PocketBase's database, set once via the
  # superuser UI (no env-var path for provider config) — paste it during
  # Part B of docs/plans/archive/2026-11-09-beszel-keycloak-sso.md so
  # both sides match; refresh steps live in docs/homelab.md → Beszel.
  client_secret = data.sops_file.secrets.data["beszel_client_secret"]

  # PocketBase derives the redirect URI from the request origin plus the
  # fixed callback path /api/oauth2-redirect. Logins opened at the hub
  # aspect's spare vhost (beszel.directions.ritter.family) would send a
  # different origin and fail Keycloak's redirect check — the public
  # FQDN is the one supported entry point (same caveat as PVE).
  valid_redirect_uris = [
    "https://beszel.ritter.family/api/oauth2-redirect",
  ]
}
