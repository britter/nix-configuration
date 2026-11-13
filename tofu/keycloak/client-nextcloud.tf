# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "nextcloud" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "nextcloud"
  name      = "Nextcloud"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # user_oidc sends PKCE by default whenever the IdP advertises S256
  # (Keycloak does — verified in the 8.11.0 source, LoginController.php),
  # so S256 is enforced here like on every other client. Land this PR
  # before the stage-1 module change (PR 2, docs/plans/nextcloud-keycloak-sso.md
  # Part C), or the deployed button would target a client that does not
  # exist yet.
  pkce_code_challenge_method = "S256"

  # Operator-generated and seeded into both sops stores (tofu's
  # secrets.json for the pipeline, srv-prod-2's yaml for the app's
  # oneshot) so the two sides match by construction. Seeding command:
  # docs/plans/nextcloud-keycloak-sso.md, Part A.
  client_secret = data.sops_file.secrets.data["nextcloud_client_secret"]

  # user_oidc builds the redirect_uri with
  # linkToRouteAbsolute('user_oidc.login.code') (verified,
  # LoginController.php) — whether Nextcloud renders the pretty form or
  # the index.php form depends on the instance's URL-rewrite config,
  # which the nixos module does not pin. Both variants are whitelisted
  # so the client is correct either way; exactly one is exercised (the
  # app's admin settings page displays the effective one), the other is
  # inert. Logins opened at the aspect vhost
  # (nextcloud.srv-prod-2.ritter.family) would send a different origin
  # and fail Keycloak's redirect check — the public FQDN is the one
  # supported entry point (same caveat as every other service).
  valid_redirect_uris = [
    "https://nextcloud.ritter.family/apps/user_oidc/code",
    "https://nextcloud.ritter.family/index.php/apps/user_oidc/code",
  ]
}
