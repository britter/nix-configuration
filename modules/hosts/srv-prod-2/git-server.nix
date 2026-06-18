{ config, ... }:
let
  inherit (config.flake.modules.nixos) git-server;
in
{
  flake.modules.nixos.srv-prod-2 =
    { config, ... }:
    {
      imports = [ git-server ];

      systemd.tmpfiles.rules = [
        "d /var/backups 0777 root root"
      ];

      sops.secrets."restic/git/repository-password" = { };
      sops.secrets."restic/git/minio-access-key-id" = { };
      sops.secrets."restic/git/minio-secret-access-key" = { };
      sops.templates."restic/git/secrets.env" = {
        content = ''
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/git/minio-access-key-id"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/git/minio-secret-access-key"}
          RESTIC_PASSWORD=${config.sops.placeholder."restic/git/repository-password"}
        '';
      };

      services.restic.backups.git = {
        environmentFile = config.sops.templates."restic/git/secrets.env".path;
        paths = [ "/srv/git" ];
        repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/git";
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
