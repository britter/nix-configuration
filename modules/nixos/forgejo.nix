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

      services.forgejo = {
        enable = true;
        database.type = "sqlite3";
        settings = {
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
          adminCmd = "${lib.getExe config.services.forgejo.package} admin user";
          pwd = config.sops.secrets."forgejo/admin-user-password";
          user = "britter"; # Note, Forgejo doesn't allow creation of an account named "admin"
        in
        ''
          ${adminCmd} create --admin --email "root@localhost" --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
          ## uncomment this line to change an admin user which was already created
          # ${adminCmd} change-password --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
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
