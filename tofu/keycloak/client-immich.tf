# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "immich" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "immich"
  name      = "Immich"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # Immich's openid-client sends PKCE S256 whenever the IdP's discovery
  # document advertises support (supportsPKCE(),
  # server/src/repositories/oauth.repository.ts, v3.4.1 — the realm
  # advertises S256), so S256 is enforced here like on every other
  # client. Land this PR before the stage-1 module change (PR 2), or the
  # deployed button would target a client that does not exist yet.
  pkce_code_challenge_method = "S256"

  # Operator-generated and seeded into both sops stores (tofu's
  # secrets.json for the pipeline, srv-prod-4's yaml for the app's
  # config file) so the two sides match by construction. Seeding
  # command: docs/plans/immich-keycloak-sso.md, Part A.
  client_secret = data.sops_file.secrets.data["immich_client_secret"]

  # The web client builds the redirect_uri from its own origin:
  # <origin>/auth/login for sign-in and <origin>/user-settings for
  # manually linking an account (upstream docs "Prerequisites", verified
  # against the v3.4.1 sources). The mobile app's callback is the custom
  # scheme app.immich:///oauth-callback (required for the app's OAuth
  # flow; the app carries state + PKCE verifier in the callback body, so
  # no cookies are needed there). Logins opened at the aspect vhost
  # (photos.srv-prod-4.ritter.family) would send a different origin and
  # fail Keycloak's redirect check — the public FQDN is the one
  # supported entry point (same caveat as every other service).
  valid_redirect_uris = [
    "https://photos.ritter.family/auth/login",
    "https://photos.ritter.family/user-settings",
    "app.immich:///oauth-callback",
  ]
}
