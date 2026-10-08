_: {
  flake.modules.nixos.object-storage-sync-on-srv-offsite-1 =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      sops.secrets."srv-prod-3/garage/global-read-key-id" = { };
      sops.secrets."srv-prod-3/garage/global-read-secret-key" = { };
      sops.secrets."garage/global-write-key-id" = { };
      sops.secrets."garage/global-write-secret-key" = { };
      sops.templates."rclone.conf" = {
        content = ''
          [srv-prod-3]
          type = s3
          provider = Other
          env_auth = false
          region = garage
          access_key_id = ${config.sops.placeholder."srv-prod-3/garage/global-read-key-id"}
          secret_access_key = ${config.sops.placeholder."srv-prod-3/garage/global-read-secret-key"}
          endpoint = https://garage.srv-prod-3.ritter.family
          location_constraint =
          server_side_encryption =

          [srv-offsite-1]
          type = s3
          provider = Other
          env_auth = false
          region = garage
          access_key_id = ${config.sops.placeholder."garage/global-write-key-id"}
          secret_access_key = ${config.sops.placeholder."garage/global-write-secret-key"}
          endpoint = http://localhost:3900
          location_constraint =
          server_side_encryption =
        '';
      };

      # nightly object-storage-sync
      systemd.timers.nightly-object-storage-sync = {
        description = "Nightly timer to wake up the system for the object storage sync";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "02:00";
          Persistent = true;
          WakeSystem = true;
        };
      };
      systemd.services.nightly-object-storage-sync = {
        description = "Nightly object storage sync that suspends the system after running";
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
