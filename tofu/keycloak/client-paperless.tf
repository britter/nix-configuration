# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "paperless" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "paperless"
  name      = "Paperless-ngx"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # allauth's OIDC provider sends PKCE only when the app config enables
  # it (default off) — the paperless module sets `oauth_pkce_enabled`
  # (see docs/plans/paperless-keycloak-sso.md, Part C), so S256 is
  # enforced here like on every other client. Land this PR before the
  # stage-1 module change (PR 2), or the deployed button would fail
  # Keycloak's challenge check.
  pkce_code_challenge_method = "S256"

  # Operator-generated and seeded into both sops stores (tofu's
  # secrets.json for the pipeline, srv-prod-2's yaml for the app's env
  # template) so the two sides match by construction. Seeding command:
  # docs/plans/paperless-keycloak-sso.md, Part A.
  client_secret = data.sops_file.secrets.data["paperless_client_secret"]

  # allauth derives the callback from the request origin plus the fixed
  # path /accounts/oidc/<provider_id>/login/callback/ (provider_id
  # "keycloak", set in the app config). Logins opened at the aspect
  # vhost (documents.srv-prod-2.ritter.family) would send a different
  # origin and fail Keycloak's redirect check — the public FQDN is the
  # one supported entry point (same caveat as PVE, Beszel, Stirling).
  valid_redirect_uris = [
    "https://documents.ritter.family/accounts/oidc/keycloak/login/callback/",
  ]
}
