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

      services.immich = {
        enable = true;
        # see https://docs.immich.app/install/config-file
        settings = {
          server.externalDomain = "https://photos.ritter.family";
          storageTemplate.enabled = true;
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
