{
  pkgs,
  lib,
  config,
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
      nextcloud = {
        enable = true;
        stage = "test";
      };
      calibre-web.enable = true;
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

  services.restic.restores.git = {
    environmentFile = config.sops.templates."restic/git/secrets.env".path;
    paths = [ "/srv/git" ];
    repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/git";
  };

  services.restic.restores.calibre = {
    environmentFile = config.sops.templates."restic/calibre/secrets.env".path;
    paths = [
      "/var/lib/calibre-web"
      "/var/lib/calibre-library"
    ];
    repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/calibre";
    restorePostCommand = "systemctl restart calibre-web.service";
  };

  services.restic.backups.nextcloud = {
    environmentFile = config.sops.templates."restic/nextcloud/secrets.env".path;
    paths = [
      "/var/lib/nextcloud/data"
      "/var/backups/nextcloud"
    ];
    repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/nextcloud";
    timerConfig = null;
  };
  systemd.timers.restic-restore-nextcloud = {
    description = "Timer for restoring nextcloud";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services.restic-restore-nextcloud =
    let
      occ = lib.getExe config.services.nextcloud.occ;
    in
    {
      description = "Runs restic restore to restore nextcloud";
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${occ} maintenance:mode --on";
        ExecStart = ''
          restic-nextcloud restore latest --delete
          ${lib.getExe pkgs.sudo} -u postgres ${pkgs.postgresql}/bin/pg_restore --clean --create -d nextcloud /var/backups/nextcloud/nextcloud.dump
        '';
        ExecStartPost = "${occ} maintenance:mode --off";
      };
    };

  services.restic.restores.vaultwarden = {
    environmentFile = config.sops.templates."restic/vaultwarden/secrets.env".path;
    paths = [
      "/var/lib/bitwarden_rs"
      "/var/backups/vaultwarden"
    ];
    repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/vaultwarden";
    restorePrepareCommand = "systemctl stop vaultwarden";
    restorePostCommand = ''
      sudo -u postgres psql --command="DROP DATABASE IF EXISTS vaultwarden;"
      sudo -u postgres psql --command="CREATE DATABASE vaultwarden OWNER vaultwarden;"
      sudo -u vaultwarden psql --dbname=vaultwarden --file=/var/backups/waultwarden/vaultwarden.dump
      systemctl restart vaultwarden
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
