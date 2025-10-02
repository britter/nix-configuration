{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    ../../../modules
    inputs.nixos-facter-modules.nixosModules.facter
  ];

  facter.reportPath = ./facter.json;
  # see https://github.com/numtide/nixos-facter-modules/issues/62
  facter.detected.dhcp.enable = false;

  my = {
    host.role = "server";
    modules = {
      disko = {
        enable = true;
        bootDisk = "/dev/nvme0n1"; # 256GB
        storageDisk = "/dev/sda"; # 2TB
      };
      minio.enable = true;
      tailscale.enable = true;
    };
  };

  sops.secrets."srv-prod-3/minio/access-key" = { };
  sops.secrets."srv-prod-3/minio/secret-key" = { };
  sops.templates."rclone.conf" = {
    content = ''
      [srv-prod-3]
      type = s3
      provider = Minio
      env_auth = false
      region = eu-central-1
      access_key_id = ${config.sops.placeholder."srv-prod-3/minio/access-key"}
      secret_access_key = ${config.sops.placeholder."srv-prod-3/minio/secret-key"}
      endpoint = https://minio.srv-prod-3.ritter.family
      location_constraint =
      server_side_encryption =

      [srv-offsite-1]
      type = s3
      provider = Minio
      env_auth = false
      region = eu-central-1
      access_key_id = ${config.sops.placeholder."minio/root-user"}
      secret_access_key = ${config.sops.placeholder."minio/root-password"}
      endpoint = http://localhost:9000
      location_constraint =
      server_side_encryption =
    '';
  };

  systemd.services.minio-sync = {
    description = "Synchronizes the contents of the minio on srv-prod-3 to the minio on this server.";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.rclone} sync srv-prod-3: srv-offsite-1: --config ${
        config.sops.templates."rclone.conf".path
      }";
    };
  };

  systemd.services.nightly-supend = {
    description = "Suspend after nightly MinIO sync";
    after = [ "minio-sync.service" ];
    requires = [ "minio-sync.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl suspend";
    };
  };

  systemd.timers.nightly-backup = {
    description = "Timer for nightly MinIO sync + suspend";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily 02:00";
      Persistent = true;
      WakeSystem = true;
    };
    unitConfig = {
      Requires = [ "nightly-shutdown.service" ];
    };
  };

  system.stateVersion = "25.05";
}
