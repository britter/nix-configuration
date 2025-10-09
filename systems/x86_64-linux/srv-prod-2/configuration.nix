{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../../modules
  ];

  my = {
    host = {
      role = "server";
    };
    modules = {
      proxmox-vm.enable = true;
      disko = {
        enable = true;
        bootDisk = "/dev/sda";
        storageDisk = "/dev/sdb";
      };
      git-server.enable = true;
      calibre-web.enable = true;
      nextcloud = {
        enable = true;
        stage = "production";
      };
      stirling-pdf.enable = true;
      tailscale.enable = true;
      vaultwarden.enable = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/backups 0777 root root"
    "d /var/backups/vaultwarden 0755 postgres postgres"
    "d /var/backups/nextcloud 0755 postgres postgres"
  ];

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
  services.restic.backups =
    # keep the most recent snapshot per <unit> for the last .. <unit>
    # e.g. for the last 8 weeks, we will keep the most recent snapshot of that week.
    let
      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--keep-yearly 5"
      ];
    in
    {
      git = {
        environmentFile = config.sops.templates."restic/git/secrets.env".path;
        paths = [ "/srv/git" ];
        repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/git";
        initialize = true;
        inherit pruneOpts;
      };
      calibre = {
        environmentFile = config.sops.templates."restic/calibre/secrets.env".path;
        paths = [
          "/var/lib/calibre-web"
          "/var/lib/calibre-library"
        ];
        repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/calibre";
        initialize = true;
        inherit pruneOpts;
      };
      nextcloud =
        let
          occ = lib.getExe config.services.nextcloud.occ;
        in
        {
          environmentFile = config.sops.templates."restic/nextcloud/secrets.env".path;
          paths = [
            "/var/lib/nextcloud/data"
            "/var/backups/nextcloud"
          ];
          repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/nextcloud";
          initialize = true;
          backupPrepareCommand = ''
            ${occ} maintenance:mode --on
            ${lib.getExe pkgs.sudo} -u postgres ${pkgs.postgresql}/bin/pg_dump --format=custom --file=/var/backups/nextcloud/nextcloud.dump nextcloud
          '';
          backupCleanupCommand = ''
            rm /var/backups/nextcloud/nextcloud.dump
            ${occ} maintenance:mode --off
          '';
          inherit pruneOpts;
        };
      vaultwarden = {
        environmentFile = config.sops.templates."restic/vaultwarden/secrets.env".path;
        paths = [
          "/var/lib/bitwarden_rs"
          "/var/backups/vaultwarden"
        ];
        repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/vaultwarden";
        initialize = true;
        backupPrepareCommand = ''
          systemctl stop vaultwarden
          ${lib.getExe pkgs.sudo} -u postgres ${pkgs.postgresql}/bin/pg_dump --format=custom --file=/var/backups/vaultwarden/vaultwarden.dump vaultwarden
        '';
        backupCleanupCommand = ''
          rm /var/backups/vaultwarden/vaultwarden.dump
          systemctl restart vaultwarden
        '';
        inherit pruneOpts;
      };
    };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
