_: {
  flake.modules.nixos.gatus =
    { config, ... }:
    {
      sops.secrets."gatus/brevo-smtp-username" = { };
      sops.secrets."gatus/brevo-smtp-password" = { };
      sops.templates."gatus/brevo-smtp-env" = {
        content = ''
          BREVO_SMTP_USERNAME=${config.sops.placeholder."gatus/brevo-smtp-username"}
          BREVO_SMTP_PASSWORD=${config.sops.placeholder."gatus/brevo-smtp-password"}
        '';
        restartUnits = [ "gatus.service" ];
      };

      services.gatus = {
        enable = true;
        environmentFile = config.sops.templates."gatus/brevo-smtp-env".path;
        settings = {
          web.port = 8888;

          alerting.email = {
            from = "gatus@ritter.family";
            username = "\${BREVO_SMTP_USERNAME}";
            password = "\${BREVO_SMTP_PASSWORD}";
            host = "smtp-relay.brevo.com";
            port = 587;
            to = config.systemConstants.adminEmail;
            # Applies to every endpoint that lists an email alert below.
            default-alert = {
              enabled = true;
              failure-threshold = 3;
              send-on-resolved = true;
            };
          };

          endpoints = [
            {
              name = "NextCloud";
              url = "https://nextcloud.ritter.family/status.php";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
                "[BODY].installed == true"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Vaultwarden";
              url = "https://passwords.ritter.family/alive";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Immich";
              url = "https://photos.ritter.family/api/server/ping";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
                "[BODY].res == pong"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Navidrome";
              url = "https://music.ritter.family/ping";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Calibre-Web";
              url = "https://books.ritter.family";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "AdGuard Home";
              url = "https://adguard.ritter.family";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Home Assistant";
              url = "https://homeassistant.ritter.family";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Stirling PDF";
              # /api/v1/info/status is public and unauthenticated even
              # with login on, so monitoring survives the Keycloak SSO
              # rollout — see docs/plans/stirling-pdf-keycloak-sso.md.
              url = "https://pdf.ritter.family/api/v1/info/status";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
                # unquoted compare: gatus treats a quoted RHS as
                # literal-with-quotes (Forgejo's check uses the same
                # unquoted style).
                "[BODY].status == UP"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Garage";
              url = "https://garage.srv-prod-3.ritter.family/health";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Beszel";
              url = "https://beszel.ritter.family/api/health";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "SSO";
              url = "https://account.ritter.family";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Forgejo";
              url = "https://git.ritter.family/api/healthz";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
                "[BODY].status == pass"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "IT Tools";
              url = "https://tools.ritter.family";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
            {
              name = "Paperless";
              url = "https://documents.ritter.family/accounts/login/";
              interval = "5m";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [
                { type = "email"; }
              ];
            }
          ];
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "status.ritter.family";
            target = "http://localhost:${toString config.services.gatus.settings.web.port}";
          }
        ];
      };
    };
}
