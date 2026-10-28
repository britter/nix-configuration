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

# Personal identities, managed like everything else. No password here —
# passwords are set by the user via the console or the forgot-password
# mail; an initial_password would land in the tofu state.
resource "keycloak_user" "bene" {
  realm_id = keycloak_realm.homelab.id
  username = "bene"
  enabled  = true

  email          = "beneritter@gmail.com"
  email_verified = true
}
