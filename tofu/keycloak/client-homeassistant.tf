# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "homeassistant" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "homeassistant"
  name      = "Home Assistant"
  enabled   = true

  # Deliberately PUBLIC, unlike the other clients: Home Assistant runs on
  # the HAOS Green appliance, which has no sops store — a confidential
  # secret would live only in device-local files (/config/secrets.yaml or
  # UI .storage) with no git source of truth and nothing to verify it
  # against. The integration's own docs recommend a public client with
  # redirect-URI + PKCE for home settings; hass-oidc-auth sends PKCE
  # (S256) by default, so the enforcement below is the security model.
  # See docs/plans/homeassistant-keycloak-sso.md.
  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # hass-oidc-auth sends PKCE (S256) on the authorization-code flow
  # (RFC 7636); only features.disable_rfc7636 would turn it off, left at
  # its default false.
  pkce_code_challenge_method = "S256"

  # hass-oidc-auth builds the redirect URI from the request origin plus
  # the fixed callback path /auth/oidc/callback. Logins opened at the raw
  # LAN address (http://192.168.20.234:8123) would send a different origin
  # and fail Keycloak's redirect check — the public FQDN is the one
  # supported SSO entry point (same caveat as PVE and Beszel); direct LAN
  # access uses the local password login, which stays enabled as
  # break-glass.
  valid_redirect_uris = [
    "https://homeassistant.ritter.family/auth/oidc/callback",
  ]
}
