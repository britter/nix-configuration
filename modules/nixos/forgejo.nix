_: {
  flake.modules.nixos.forgejo =
    { config, lib, ... }:
    {
      # All forgejo secrets: owned by the forgejo user, and a rotation
      # restarts the unit — credentials are bound at unit start (the
      # preStart reads the admin password, LoadCredential injects the
      # mailer credentials once), so a rotated secret must not leave a
      # stale process reading old values.
      sops.secrets."forgejo/admin-user-password" = {
        owner = "forgejo";
        restartUnits = [ "forgejo.service" ];
      };
      sops.secrets."forgejo/smtp-username" = {
        owner = "forgejo";
        restartUnits = [ "forgejo.service" ];
      };
      sops.secrets."forgejo/smtp-password" = {
        owner = "forgejo";
        restartUnits = [ "forgejo.service" ];
      };
      sops.secrets."forgejo/keycloak-client-secret" = {
        owner = "forgejo";
        restartUnits = [ "forgejo.service" ];
      };

      services.forgejo = {
        enable = true;
        database.type = "sqlite3";
        settings = {
          # Keycloak SSO: link IdP identities onto existing accounts by
          # e-mail; auto-create accounts for users that exist in the IdP.
          # Safe because the realm has registration off — every account is
          # admin-provisioned, with unique admin-set e-mails — and because
          # the account e-mails were activated first (forgejo plan, part A
          # gate: docs/plans/archive/2026-10-29-forgejo-keycloak-sso-on-srv-prod-6.md).
          "oauth2_client" = {
            ENABLE_AUTO_REGISTRATION = true;
            ACCOUNT_LINKING = "auto";
            USERNAME = "preferred_username";
          };
          mailer = {
            # Brevo relay, same one vaultwarden and the Keycloak realm use
            # (own SMTP key, credentials via secrets/mail below). Needed
            # before any account e-mail change: activation mails have to
            # actually arrive (staged rollout, plan PR 4a).
            ENABLED = true;
            PROTOCOL = "smtp+starttls";
            SMTP_ADDR = "smtp-relay.brevo.com";
            SMTP_PORT = 587;
            FROM = "git@ritter.family";
          };
          server = {
            DOMAIN = "git.ritter.family";
            ROOT_URL = "https://git.ritter.family/";
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
            DISABLE_SSH = true;
          };
          service.DISABLE_REGISTRATION = true;
        };
        # SMTP credentials are injected as runtime credentials
        # (environment-to-ini) so they never appear in the generated
        # app.ini; keys take priority over settings.
        secrets.mailer = {
          USER = config.sops.secrets."forgejo/smtp-username".path;
          PASSWD = config.sops.secrets."forgejo/smtp-password".path;
        };
      };

      systemd.services.forgejo.preStart =
        let
          forgejoCmd = "${lib.getExe config.services.forgejo.package}";
          adminCmd = "${forgejoCmd} admin user";
          pwd = config.sops.secrets."forgejo/admin-user-password";
          keycloakSecret = config.sops.secrets."forgejo/keycloak-client-secret";
          user = "britter"; # Note, Forgejo doesn't allow creation of an account named "admin"
        in
        ''
          ${adminCmd} create --admin --email "root@localhost" --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
          ## uncomment this line to change an admin user which was already created
          # ${adminCmd} change-password --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true

          # Keycloak OAuth2 source. Idempotent creation — grep-guard, the
          # source is created once and never rewritten (a rotated client
          # secret needs `forgejo admin auth update-oauth`, see the forgejo
          # plan's Known effects). The callback URL on the Keycloak side
          # must be /user/oauth2/Keycloak/callback — it embeds the source
          # NAME. Scopes are comma-separated: forgejo 15's `--scopes` is a
          # urfave/cli v3 StringSliceFlag, values split on commas only
          # (spaces would become a single bogus scope literal).
          ${forgejoCmd} admin auth list | grep -q Keycloak || \
            ${forgejoCmd} admin auth add-oauth \
              --name=Keycloak \
              --provider=openidConnect \
              --key=forgejo \
              --secret="$(tr -d '\n' < ${keycloakSecret.path})" \
              --auto-discover-url=https://account.ritter.family/realms/homelab/.well-known/openid-configuration \
              --scopes=openid,email,profile
        '';

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "git.${config.networking.hostName}.ritter.family";
            aliases = [ "git.ritter.family" ];
            target = "http://localhost:3000";
            maxBodySize = "512M";
          }
        ];
      };
    };
}
