{ config, ... }:
let
  inherit (config.flake.modules.nixos) calibre-web;
in
{
  flake.modules.nixos.srv-prod-2 =
    { config, ... }:
    {
      imports = [ calibre-web ];

      sops.secrets."restic/calibre/repository-password" = { };
      sops.secrets."restic/calibre/minio-access-key-id" = { };
      sops.secrets."restic/calibre/minio-secret-access-key" = { };
      sops.templates."restic/calibre/secrets.env" = {
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/calibre/minio-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/calibre/minio-secret-access-key"}
          RESTIC_PASSWORD=${config.sops.placeholder."restic/calibre/repository-password"}
        '';
      };

      services.restic.backups.calibre = {
        environmentFile = config.sops.templates."restic/calibre/secrets.env".path;
        paths = [
          "/var/lib/calibre-web"
          "/var/lib/calibre-library"
        ];
        repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/calibre";
        initialize = true;
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
