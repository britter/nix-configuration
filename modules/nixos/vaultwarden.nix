_: {
  flake.modules.nixos.vaultwarden =
    { config, ... }:
    {
      sops.secrets."vaultwarden/admin-token" = { };
      sops.secrets."vaultwarden/smtp-username" = { };
      sops.secrets."vaultwarden/smtp-password" = { };
      sops.templates."vaultwarden.env" = {
        owner = "vaultwarden";
        content = ''
          ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
          SMTP_USERNAME=${config.sops.placeholder."vaultwarden/smtp-username"}
          SMTP_PASSWORD=${config.sops.placeholder."vaultwarden/smtp-password"}
        '';
      };
      services.vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        environmentFile = config.sops.templates."vaultwarden.env".path;
        config = {
          DOMAIN = "https://passwords.ritter.family";
          SIGNUPS_ALLOWED = false;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          DATABASE_URL = "postgresql:///vaultwarden?host=/run/postgresql";
          SMTP_HOST = "smtp-relay.brevo.com";
          SMTP_PORT = 587;
          SMTP_SECURITY = "starttls";
          SMTP_FROM = "passwords@ritter.family";
        };
      };
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "vaultwarden" ];
        ensureUsers = [
          {
            name = "vaultwarden";
            ensureDBOwnership = true;
          }
        ];
      };
      systemd.services.vaultwarden = {
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];
      };
      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "passwords.${config.networking.hostName}.ritter.family";
            aliases = [ "passwords.ritter.family" ];
            target = "http://localhost:8222";
          }
        ];
      };
    };
}
