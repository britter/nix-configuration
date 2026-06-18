_: {
  flake.modules.nixos.minio-sync-on-srv-offsite-1 =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
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

      # nightly minio-sync
      systemd.timers.nightly-minio-sync = {
        description = "Nightly timer to wake up the system for the minio sync";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "02:00";
          Persistent = true;
          WakeSystem = true;
        };
      };
      systemd.services.nightly-minio-sync = {
        description = "Nightly minio sync that suspends the system after running";
        serviceConfig = {
          Type = "oneshot";
          # prefix ExecStart with - so that ExecStartPost is executed even if sync fails
          ExecStart = "-${lib.getExe pkgs.rclone} sync srv-prod-3: srv-offsite-1: --config ${
            config.sops.templates."rclone.conf".path
          }";
          ExecStartPost = "${pkgs.systemd}/bin/systemctl suspend";
        };
      };
    };
}
