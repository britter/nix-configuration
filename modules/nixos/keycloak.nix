_: {
  flake.modules.nixos.keycloak =
    { config, ... }:
    let
      fqdn = "account.ritter.family";
      localFqdn = "account.${config.networking.hostName}.ritter.family";
    in
    {
      services.keycloak = {
        enable = true;
        database.passwordFile = config.sops.secrets."keycloak/database-password".path;
        settings = {
          # Full URL: pins scheme, port and context path; all frontend URLs
          # use it, regardless of the vhost the request arrived at.
          hostname = "https://${fqdn}";
          # Edge TLS termination in front of Keycloak.
          http-enabled = true;
          proxy-headers = "xforwarded";
          # Bind to loopback only; nginx is the only consumer.
          http-host = "127.0.0.1";
          # nginx owns 80/443 on this host.
          http-port = 8080;
        };
      };

      sops.secrets."keycloak/database-password" = { };
      sops.secrets."keycloak/admin-password" = { };
      # Bootstrap/recovery admin. Keycloak only creates the user if it does
      # not exist, so this is inert after first start and acts as a recovery
      # path per https://www.keycloak.org/server/bootstrap-admin-recovery.
      sops.templates."keycloak-bootstrap-env".content = ''
        KC_BOOTSTRAP_ADMIN_USERNAME=admin
        KC_BOOTSTRAP_ADMIN_PASSWORD=${config.sops.placeholder."keycloak/admin-password"}
      '';
      systemd.services.keycloak.serviceConfig.EnvironmentFile =
        config.sops.templates."keycloak-bootstrap-env".path;

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = localFqdn;
            target = "http://127.0.0.1:8080";
            # The account console hands back a large cookie bundle; nginx's
            # 4k default proxy_buffer_size 502s on it ("upstream sent too
            # big header"). Raised on directions' vhost too.
            extraConfig = "proxy_buffer_size 16k;";
          }
        ];
      };
    };
}
