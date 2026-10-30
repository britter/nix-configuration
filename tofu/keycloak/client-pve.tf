# One OIDC client per service, one file per client.
resource "keycloak_openid_client" "pve" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "pve"
  name      = "Proxmox VE"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  # PVE does PKCE entirely server-side: proxmox-openid generates the
  # challenge/verifier pair per login and redeems the code with its own
  # verifier (the verifier never leaves the hypervisor). Enforceable
  # since the 9.x line; pve-manager/9.2.21 confirmed 2026-10-30
  # (docs/plans/archive/2026-10-30-proxmox-keycloak-sso.md, Step 0).
  pkce_code_challenge_method = "S256"

  # Operator-generated and seeded into sops (tofu/keycloak/secrets.json).
  # PVE keeps its own copy in /etc/pve/domains.cfg, set once via pveum —
  # rotation runbook: docs/plans/archive/2026-10-30-proxmox-keycloak-sso.md → Known effects.
  client_secret = data.sops_file.secrets.data["pve_client_secret"]

  # The PVE web GUI sends its window origin as the IdP redirect-url
  # (pve-manager LoginWindow.js: `const redirectURL = location.origin`),
  # so the URI is the exact origin without a path or trailing slash.
  # Logins opened at https://<ip>:8006 send a different origin and fail
  # Keycloak's redirect check — the proxied FQDN is the one supported
  # entry point.
  valid_redirect_uris = [
    "https://pve.ritter.family",
  ]
}
