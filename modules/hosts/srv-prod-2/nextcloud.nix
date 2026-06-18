{ config, ... }:
let
  inherit (config.flake.modules.nixos) nextcloud;
in
{
  flake.modules.nixos.srv-prod-2 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ nextcloud ];

      boot.supportedFilesystems = [ "nfs" ];
      fileSystems."/srv/nextcloud-data" = {
        fsType = "nfs";
        device = "storage.ritter.family:/mnt/default-pool/nextcloud";
      };

      systemd.services.nginx = {
        unitConfig = {
          RequiresMountsFor = "/srv/nextcloud-data";
        };
      };
      services.nextcloud.settings.datadirectory = "/srv/nextcloud-data";

      systemd.tmpfiles.rules = [
        "d /var/backups/nextcloud 0755 postgres postgres"
      ];

      sops.secrets."restic/nextcloud/repository-password" = { };
      sops.secrets."restic/nextcloud/minio-access-key-id" = { };
      sops.secrets."restic/nextcloud/minio-secret-access-key" = { };
      sops.templates."restic/nextcloud/secrets.env" = {
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/nextcloud/minio-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/nextcloud/minio-secret-access-key"}
          RESTIC_PASSWORD=${config.sops.placeholder."restic/nextcloud/repository-password"}
        '';
      };

      services.restic.backups.nextcloud =
        let
          occ = lib.getExe config.services.nextcloud.occ;
          pg_dump = "${config.services.postgresql.package}/bin/pg_dump";
        in
        {
          environmentFile = config.sops.templates."restic/nextcloud/secrets.env".path;
          paths = [
            "/srv/nextcloud-data"
            "/var/backups/nextcloud"
          ];
          repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/nextcloud";
          initialize = true;
          backupPrepareCommand = ''
            ${occ} maintenance:mode --on
            ${lib.getExe pkgs.sudo} -u postgres ${pg_dump} --format=custom --file=/var/backups/nextcloud/nextcloud.dump nextcloud
          '';
          backupCleanupCommand = ''
            rm /var/backups/nextcloud/nextcloud.dump
            ${occ} maintenance:mode --off
          '';
          pruneOpts = [
            "--keep-daily 14"
            "--keep-weekly 8"
            "--keep-monthly 12"
            "--keep-yearly 5"
          ];
          timerConfig = {
            OnCalendar = "00:00";
            RandomizedDelaySec = "30mm";
            Persistent = true;
          };
        };
    };
}
