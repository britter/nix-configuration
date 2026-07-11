{ config, ... }:
let
  inherit (config.flake.modules.nixos) paperless;
  restic = import ./_restic-constants.nix;
in
{
  flake.modules.nixos.paperless-on-srv-prod-2 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ paperless ];

      boot.supportedFilesystems = [ "nfs" ];
      fileSystems."/srv/paperless-media" = {
        fsType = "nfs";
        device = "storage.ritter.family:/mnt/default-pool/paperless";
      };
      services.paperless.mediaDir = "/srv/paperless-media";

      # Gate every paperless unit that touches the media dir on the NFS mount.
      systemd.services.paperless-web.unitConfig.RequiresMountsFor = "/srv/paperless-media";
      systemd.services.paperless-consumer.unitConfig.RequiresMountsFor = "/srv/paperless-media";
      systemd.services.paperless-scheduler.unitConfig.RequiresMountsFor = "/srv/paperless-media";
      systemd.services.paperless-task-queue.unitConfig.RequiresMountsFor = "/srv/paperless-media";

      systemd.tmpfiles.rules = [
        "d /var/backups/paperless 0755 postgres postgres"
      ];

      sops.secrets."restic/paperless/repository-password" = { };
      sops.secrets."restic/paperless/minio-access-key-id" = { };
      sops.secrets."restic/paperless/minio-secret-access-key" = { };
      sops.templates."restic/paperless/secrets.env" = {
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/paperless/minio-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/paperless/minio-secret-access-key"}
          RESTIC_PASSWORD=${config.sops.placeholder."restic/paperless/repository-password"}
        '';
      };

      services.restic.backups.paperless =
        let
          pg_dump = "${config.services.postgresql.package}/bin/pg_dump";
        in
        {
          environmentFile = config.sops.templates."restic/paperless/secrets.env".path;
          paths = [
            "/srv/paperless-media"
            "/var/backups/paperless"
          ];
          repository = "${restic.bucket}/paperless";
          initialize = true;
          backupPrepareCommand = ''
            ${lib.getExe pkgs.sudo} -u postgres ${pg_dump} --format=custom --file=/var/backups/paperless/paperless.dump paperless
          '';
          backupCleanupCommand = ''
            rm -f /var/backups/paperless/paperless.dump
          '';
          inherit (restic) pruneOpts timerConfig;
        };
    };
}
