{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.vaultwarden;
in {
  options.my.modules.vaultwarden = {
    enable = lib.mkEnableOption "vaultwarden";
  };
  config = lib.mkIf cfg.enable {
    sops.secrets."vaultwarden/admin-token" = {};
    sops.templates."vaultwarden.env" = {
      owner = "vaultwarden";
      content = ''
        ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
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
      };
    };
    services.postgresql = {
      enable = true;
      ensureDatabases = ["vaultwarden"];
      ensureUsers = [
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
        }
      ];
    };
    systemd.services.vaultwarden = {
      after = ["postgresql.service"];
      requires = ["postgresql.service"];
    };
    my.modules.https-proxy = {
      enable = true;
      configurations = [
        {
          fqdn = "passwords.${config.my.host.name}.ritter.family";
          target = "http://localhost:8222";
        }
      ];
    };
  };
}
