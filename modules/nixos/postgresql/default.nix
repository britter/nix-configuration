{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.modules.postgresql;
in {
  options.my.modules.postgresql = {
    enable = lib.mkEnableOption "postgresql";
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      ensureDatabases = ["nextcloud"];
      ensureUsers = [
        {
          name = "nextcloud";
          ensureDBOwnership = true;
        }
      ];
      enableTCPIP = true;
      authentication = ''
        # type  database   user       IP                                      auth
        host    nextcloud  nextcloud  ${config.my.homelab.cyberoffice.ip}/32  md5
      '';
    };

    # Set the nextcloud postgresql password
    sops.secrets."postgresql/nextcloud-user-password" = {
      restartUnits = ["postgresql.service"];
      sopsFile = "${toString inputs.self}/systems/_shared-secrets/warehouse/cyberoffice-secrets.yaml";
    };
    systemd.services.postgresql.postStart = let
      passwordFilePath = config.sops.secrets."postgresql/nextcloud-user-password".path;
    in ''
      $PSQL -tA <<'EOF'
        DO $$
        DECLARE password TEXT;
        BEGIN
          password := trim(both from replace(pg_read_file('${passwordFilePath}'), E'\n', '''));
          EXECUTE format('ALTER ROLE nextcloud WITH PASSWORD '''%s''';', password);
        END $$;
      EOF
    '';

    networking.firewall.allowedTCPPorts = [config.services.postgresql.settings.port];
  };
}
