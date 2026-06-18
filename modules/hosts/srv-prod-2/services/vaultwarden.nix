{ config, ... }:
let
  inherit (config.flake.modules.nixos) vaultwarden;
  restic = import ./_restic-constants.nix;
in
{
  flake.modules.nixos.vaultwarden-on-srv-prod-2 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ vaultwarden ];

      systemd.tmpfiles.rules = [
        "d /var/backups/vaultwarden 0755 postgres postgres"
      ];

      sops.secrets."restic/vaultwarden/repository-password" = { };
      sops.secrets."restic/vaultwarden/minio-access-key-id" = { };
      sops.secrets."restic/vaultwarden/minio-secret-access-key" = { };
      sops.templates."restic/vaultwarden/secrets.env" = {
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/vaultwarden/minio-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/vaultwarden/minio-secret-access-key"}
          RESTIC_PASSWORD=${config.sops.placeholder."restic/vaultwarden/repository-password"}
        '';
      };

      services.restic.backups.vaultwarden =
        let
          pg_dump = "${config.services.postgresql.package}/bin/pg_dump";
        in
        {
          environmentFile = config.sops.templates."restic/vaultwarden/secrets.env".path;
          paths = [
            "/var/lib/bitwarden_rs"
            "/var/backups/vaultwarden"
          ];
          repository = "${restic.bucket}/vaultwarden";
          initialize = true;
          backupPrepareCommand = ''
            systemctl stop vaultwarden
            ${lib.getExe pkgs.sudo} -u postgres ${pg_dump} --format=custom --file=/var/backups/vaultwarden/vaultwarden.dump vaultwarden
          '';
          backupCleanupCommand = ''
            rm /var/backups/vaultwarden/vaultwarden.dump
            systemctl restart vaultwarden
          '';
          inherit (restic) pruneOpts timerConfig;
        };
    };
}
