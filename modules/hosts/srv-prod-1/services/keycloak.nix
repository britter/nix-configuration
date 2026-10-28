{ config, ... }:
let
  inherit (config.flake.modules.nixos) keycloak;
  restic = import ./_restic-constants.nix;
in
{
  flake.modules.nixos.keycloak-on-srv-prod-1 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ keycloak ];

      systemd.tmpfiles.rules = [
        "d /var/backups/keycloak 0750 postgres postgres"
      ];

      sops.secrets."restic/keycloak/repository-password" = { };
      sops.secrets."restic/keycloak/garage-access-key-id" = { };
      sops.secrets."restic/keycloak/garage-secret-access-key" = { };
      sops.templates."restic/keycloak/env" = {
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/keycloak/garage-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/keycloak/garage-secret-access-key"}
          RESTIC_PASSWORD=${config.sops.placeholder."restic/keycloak/repository-password"}
        '';
      };

      services.restic.backups.keycloak =
        let
          pg_dump = "${config.services.postgresql.package}/bin/pg_dump";
        in
        {
          environmentFile = config.sops.templates."restic/keycloak/env".path;
          paths = [ "/var/backups/keycloak" ];
          repository = "${restic.bucket-prefix}-keycloak";
          initialize = true;
          backupPrepareCommand = ''
            ${lib.getExe pkgs.sudo} -u postgres ${pg_dump} --format=custom --file=/var/backups/keycloak/keycloak.dump keycloak
          '';
          backupCleanupCommand = ''
            rm /var/backups/keycloak/keycloak.dump
          '';
          inherit (restic) pruneOpts timerConfig;
        };
    };
}
