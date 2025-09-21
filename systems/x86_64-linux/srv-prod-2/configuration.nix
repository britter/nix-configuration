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
    "d /var/backups/postgres 0755 postgres postgres"
  ];
  users.users = {
    calibre-web = {
      openssh.authorizedKeys.keyFiles = [ ../srv-test-2/ssh_srv-test-2_ed25519_key.pub ];
      useDefaultShell = true;
    };
    nextcloud = {
      openssh.authorizedKeys.keyFiles = [ ../srv-test-2/ssh_srv-test-2_ed25519_key.pub ];
      useDefaultShell = true;
    };
    git = {
      openssh.authorizedKeys.keyFiles = [ ../srv-test-2/ssh_srv-test-2_ed25519_key.pub ];
      useDefaultShell = true;
    };
    vaultwarden = {
      openssh.authorizedKeys.keyFiles = [ ../srv-test-2/ssh_srv-test-2_ed25519_key.pub ];
      useDefaultShell = true;
    };
  };

  sops.secrets."restic/repository-password" = { };
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
  services.restic.backups = {
    git = {
      environmentFile = config.sops.templates."restic/git/secrets.env".path;
      paths = [ "/srv/git" ];
      repository = "s3:https://minio.srv-prod-3.ritter.family/restic-backups/git";
      initialize = true;
      # keep the most recent snapshot per <unit> for the last .. <unit>
      # e.g. for the last 8 weeks, we will keep the most recent snapshot of that week.
      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--keep-yearly 5"
      ];
    };
    # legacy backups, to be removed
    srv-backup-1 = {
      passwordFile = config.sops.secrets."restic/repository-password".path;
      extraOptions = [ "sftp.args='-i /etc/ssh/ssh_host_ed25519_key'" ];
      backupPrepareCommand = ''
        ${lib.getExe pkgs.sudo} -u postgres ${pkgs.postgresql}/bin/pg_dump --format=custom --file=/var/backups/postgres/nextcloud.dump nextcloud
        ${lib.getExe pkgs.sudo} -u postgres ${pkgs.postgresql}/bin/pg_dump --format=custom --file=/var/backups/postgres/vaultwarden.dump vaultwarden
      '';
      paths = [
        "/var/backups/postgres"
        "/var/lib/nextcloud/data"
        "/var/lib/bitwarden_rs"
        "/var/lib/calibre-web"
        "/var/lib/calibre-library"
        "/srv/git"
      ];
      repository = "sftp:backup@srv-backup-1.ritter.family:restic/srv-prod-1";
      initialize = true;
      # keep the most recent snapshot per <unit> for the last .. <unit>
      # e.g. for the last 8 weeks, we will keep the most recent snapshot of that week.
      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--keep-yearly 5"
      ];
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
