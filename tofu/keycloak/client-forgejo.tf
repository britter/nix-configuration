# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "forgejo" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "forgejo"
  name      = "Forgejo"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # Forgejo sends PKCE (S256) on the authorization-code flow.
  pkce_code_challenge_method = "S256"

  # Operator-generated and seeded into both sops stores (tofu's
  # secrets.json for the pipeline, srv-prod-6's yaml for Forgejo's
  # preStart) so the two sides match by construction. Setting it
  # explicitly means every apply re-sends exactly this value (
  # UpdateOpenidClient embeds `secret` in the payload); refresh pulls
  # whatever Keycloak currently holds into state either way. See the
  # Forgejo plan's Known effects for the rotation runbook:
  # docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md
  client_secret = data.sops_file.secrets.data["forgejo_client_secret"]

  # Forgejo's callback path embeds the auth source's NAME (lowercase
  # "Keycloak" in /user/oauth2/Keycloak/callback).
  valid_redirect_uris = [
    "https://git.ritter.family/user/oauth2/Keycloak/callback"
  ]
}
