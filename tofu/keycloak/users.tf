# Personal identities, managed like everything else. No password here —
# passwords are set by the user via the console or the forgot-password
# mail; an initial_password would land in the tofu state.
#
# Provisioning a new person: Keycloak-side recipe (username becomes the
# Forgejo handle, e-mail must be unique across the Forgejo userbase) in
# docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md →
# Known effects → "Provisioning a new person". Per-user roles that gate
# a service (e.g. a future PVE hypervisor access gate) go into the
# service's client file; see the README "Restricting who can use a
# client" section.
resource "keycloak_user" "bene" {
  realm_id   = keycloak_realm.homelab.id
  username   = "bene"
  first_name = "Benedikt"
  last_name  = "Ritter"
  enabled    = true

  email          = "beneritter@gmail.com"
  email_verified = true
}
