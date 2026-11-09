# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "stirling_pdf" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "stirling-pdf"
  name      = "Stirling PDF"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # Deliberately no pkce_code_challenge_method: Stirling-PDF registers the
  # provider via Spring Security's ClientRegistrations.fromIssuerLocation
  # and (being a confidential client with a secret) does not send a PKCE
  # challenge — Forgejo and Beszel enforce PKCE because their code bases
  # send it, Stirling does not. Keycloak merely does not require the
  # challenge then, so leaving it off is safe in both directions; if a
  # future Stirling version starts sending S256, setting the attribute is
  # the follow-up, not a fix.
  #
  # Operator-generated and seeded into both sops stores (tofu's
  # secrets.json for the pipeline, srv-prod-2's yaml for the app's env
  # template) so the two sides match by construction. See the Stirling PDF
  # plan's Part A for the seeding command:
  # docs/plans/stirling-pdf-keycloak-sso.md
  client_secret = data.sops_file.secrets.data["stirling_pdf_client_secret"]

  # Stirling-PDF derives the callback from the request origin plus the
  # fixed registration id of the provider block (/login/oauth2/code/keycloak).
  # Logins opened at the aspect vhost (pdf.srv-prod-2.ritter.family) would
  # send a different origin and fail Keycloak's redirect check — the
  # public FQDN is the one supported entry point (same caveat as PVE and
  # Beszel).
  valid_redirect_uris = [
    "https://pdf.ritter.family/login/oauth2/code/keycloak",
  ]
}
