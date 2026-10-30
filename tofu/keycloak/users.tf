# Personal identities, managed like everything else. No password here —
# passwords are set by the user via the console or the forgot-password
# mail; an initial_password would land in the tofu state.
#
# Provisioning a new person: Keycloak-side recipe (username becomes the
# Forgejo handle, e-mail must be unique across the Forgejo userbase) in
# docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md →
# Known effects → "Provisioning a new person". Note that per-user role
# assignment is NOT an access gate in vanilla Keycloak — see the README
# "Restricting who can use a client" section (corrected 2026-10-30):
# each service's own authorization model (PVE ACLs, Forgejo
# admin/e-mail model) is authoritative.
resource "keycloak_user" "bene" {
  realm_id   = keycloak_realm.homelab.id
  username   = "bene"
  first_name = "Benedikt"
  last_name  = "Ritter"
  enabled    = true

  email          = "beneritter@gmail.com"
  email_verified = true
}
