# Passkey enrollment (see the web_authn_passwordless_policy block in
# realm.tf for the login-side policy). This flips on Keycloak's built-in
# "Webauthn Register Passwordless" required action so users can attach a
# passkey to their account.
#
# default_action = true: every user is prompted to enroll a passkey at
# their next login. Passwords keep working as fallback — nobody is
# locked out by a lost device; they just log in with the password and
# (after logging in from any device) enroll a new passkey. If we ever go
# fully passwordless (custom browser flow with
# webauthn-authenticator-passwordless), everyone must have enrolled
# BEFORE the flow switch: users without a passkey can't even reach the
# enrollment screen in a passkey-only flow.
resource "keycloak_required_action" "webauthn_register_passwordless" {
  realm_id       = keycloak_realm.homelab.id
  alias          = "webauthn-register-passwordless"
  name           = "Webauthn Register Passwordless"
  enabled        = true
  default_action = true
}
