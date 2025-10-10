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
      RESTIC_REPOSITORY=s3:https://minio.srv-prod-3.ritter.family/restic-backups/git;
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

  # duplicate restic configurations to get a restic wrapper per backup that can be used
  # to run restore commands
  services.restic.backups.git = {
    environmentFile = config.sops.templates."restic/git/secrets.env".path;
    paths = [ "/srv/git" ];
    repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/git";
    timerConfig = null;
  };
  systemd.timers.restic-restore-git = {
    description = "Timer for restoring git";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services.restic-restore-git = {
    description = "Runs restic restore to restore the git repository";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.restic} restore latest:/srv/git --delete --no-lock --target /srv/git";
      EnvironmentFile = config.sops.templates."restic/git/secrets.env".path;
    };
  };

  services.restic.backups.calibre = {
    environmentFile = config.sops.templates."restic/calibre/secrets.env".path;
    paths = [
      "/var/lib/calibre-web"
      "/var/lib/calibre-library"
    ];
    repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/calibre";
    timerConfig = null;
  };
  systemd.timers.restic-restore-calibre = {
    description = "Timer for restoring calibre";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services.restic-restore-calibre = {
    description = "Runs restic restore to restore calibre";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "restic-calibre restore latest --delete";
    };
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

  services.restic.backups.vaultwarden = {
    environmentFile = config.sops.templates."restic/vaultwarden/secrets.env".path;
    paths = [
      "/var/lib/bitwarden_rs"
      "/var/backups/vaultwarden"
    ];
    repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/vaultwarden";
    timerConfig = null;
  };
  systemd.timers.restic-restore-vaultwarden = {
    description = "Timer for restoring vaultwarden";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services.restic-restore-vaultwarden = {
    description = "Runs restic restore to restore vaultwarden";
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "systemctl stop vaultwarden";
      ExecStart = ''
        restic-vaultwarden restore latest --delete
        ${lib.getExe pkgs.sudo} -u postgres ${pkgs.postgresql}/bin/pg_restore --clean --create -d vaultwarden /var/backups/vaultwarden/vaultwarden.dump
      '';
      ExecStartPost = "systemctl restart vaultwarden";
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
