_: {
  flake.modules.nixos.immich =
    { config, ... }:
    {
      # SMTP credentials are bound when immich-server starts (systemd
      # loads them as credentials, preStart splices them into the config
      # file), so a rotated secret must not leave a stale process.
      sops.secrets."immich/smtp-username" = {
        restartUnits = [ "immich-server.service" ];
      };
      sops.secrets."immich/smtp-password" = {
        restartUnits = [ "immich-server.service" ];
      };
      # Keycloak client secret for SSO (docs/plans/immich-keycloak-sso.md)
      # — same binding as the SMTP secrets: systemd LoadCredential,
      # spliced into /run/immich/config.json in preStart via the module's
      # _secret mechanism; rotation restarts the server.
      sops.secrets."immich/keycloak-client-secret" = {
        restartUnits = [ "immich-server.service" ];
      };

      services.immich = {
        enable = true;
        # see https://docs.immich.app/install/config-file
        settings = {
          server.externalDomain = "https://photos.ritter.family";
          storageTemplate.enabled = true;

          # Keycloak SSO (docs/plans/immich-keycloak-sso.md, stage 1):
          # adds a "Sign in with Keycloak" button beside the password
          # form. Defaults left implicit (verified against the Immich
          # 3.4.1 source, server/src/dtos/config.dto.ts): autoRegister
          # true (auto-create on first login, safe — realm allow-list),
          # autoLaunch false, scope "openid email profile", roleClaim
          # "immich_role" (never present in the realm, so admin status
          # stays Immich-side).
          oauth = {
            enabled = true;
            issuerUrl = "https://account.ritter.family/realms/homelab";
            clientId = "immich";
            buttonText = "Sign in with Keycloak";
            # Upstream default is client_secret_post; pinned to the
            # fleet-proven client_secret_basic (paperless talks to the
            # same realm with it) so the token exchange matches a
            # known-good Keycloak interaction.
            tokenEndpointAuthMethod = "client_secret_basic";
            # Resolved at runtime by the module's _secret mechanism —
            # the rendered config.json carries the sops value, never the
            # placeholder or the store path.
            clientSecret._secret = config.sops.secrets."immich/keycloak-client-secret".path;
          };
          # Stage 3 (docs/plans/immich-keycloak-sso.md Part E): SSO is
          # the only door for new logins, web and mobile alike. Break-
          # glass: remove this line and redeploy (comin) to restore the
          # password form; API keys keep authenticating regardless.
          # The admin UI cannot flip this (system settings are frozen
          # while the config file is in use) — the declaration is the
          # truth. See the plan's Rollback section.
          passwordLogin.enabled = false;
          notifications.smtp = {
            # Brevo relay, same one vaultwarden, forgejo and the Keycloak
            # realm use (own SMTP key, credentials via sops). Needed for
            # account e-mails, e.g. invited users and password resets.
            enabled = true;
            from = "photos@ritter.family";
            transport = {
              host = "smtp-relay.brevo.com";
              # secure = false upgrades to STARTTLS when the server
              # advertises it, which Brevo requires on this port.
              port = 587;
              secure = false;
              # _secret files are injected as systemd credentials and
              # spliced into /run/immich/config.json in preStart; they
              # never end up in the store or the rendered unit.
              username._secret = config.sops.secrets."immich/smtp-username".path;
              password._secret = config.sops.secrets."immich/smtp-password".path;
            };
          };
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "photos.${config.networking.hostName}.ritter.family";
            target = "http://localhost:2283";
            proxyWebsockets = true;
            maxBodySize = "50000M";
            proxyTimeout = "600s";
          }
        ];
      };
    };
}
