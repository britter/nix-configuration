# The homelab realm: conservative defaults plus the Brevo SMTP
# configuration. Identities live in users.tf, clients in one file each.
resource "keycloak_realm" "homelab" {
  realm        = "homelab"
  display_name = "ritter.family"
  enabled      = true

  # Conservative defaults; open up deliberately when a feature is needed.
  registration_allowed = false
  # "Forgot password?" on the login page — the reason this realm gets SMTP
  # in the same PR (without mail the reset link is a dead end).
  reset_password_allowed = true
  # Flip on when wanted: forces email verification on first login and after
  # address changes. Invites work without it (the admin console sends the
  # verify/set-password mails as required actions).
  verify_email = false

  ssl_required = "external"

  # Passkeys: WebAuthn passwordless as an additional login factor on top of
  # passwords — the default browser flow grows a "Sign in with passkey"
  # button plus autofill (conditional UI) on the username field, and
  # conditional 2FA is skipped for a login that used a passkey. Enrollment
  # is opt-in per user via the required action in passkey.tf. Needs the
  # "Enable Passkeys" support from Keycloak 26.7 (we run 26.8.x) and the
  # provider attribute from keycloak provider 5.8 (we pin 5.10).
  web_authn_passwordless_policy {
    relying_party_entity_name = "ritter.family SSO"
    # Passkeys are cryptographically bound to the RP ID, which must be the
    # Keycloak origin's host (a registrable-suffix exception exists, but
    # don't rely on it). Pin it so a future hostname change is a conscious
    # decision instead of silently bricking every enrolled passkey.
    relying_party_id = "account.ritter.family"
    # Synced passkeys (iCloud Keychain, Google Password Manager) are
    # discoverable credentials; "preferred" keeps hardware keys working.
    discoverable_credential = "preferred"
    # A passkey stands in for the whole credential chain — make it prove
    # user verification (biometric or device PIN), not just presence.
    user_verification_requirement = "required"
    passwordless_passkeys_enabled = true
  }

  # Outgoing mail via the Brevo account that also serves vaultwarden on
  # srv-prod-2 (own SMTP key, credentials in secrets.json). Keycloak 26 has
  # no server-wide SMTP setting — mail is realm data, so the realm resource
  # is the only place to manage it. The provider reads the password back
  # from the API, so plans stay drift-free; the value does end up in the
  # tofu state in Garage, whose bucket is readable by exactly the hosts
  # that can decrypt secrets.json (framework-13 + github-runners).
  smtp_server {
    host              = "smtp-relay.brevo.com"
    port              = "587"
    from              = "account@ritter.family"
    from_display_name = "Keycloak"
    starttls          = true

    auth {
      username = data.sops_file.secrets.data["keycloak_smtp_username"]
      password = data.sops_file.secrets.data["keycloak_smtp_password"]
    }
  }
}
