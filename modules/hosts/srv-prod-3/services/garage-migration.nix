_: {
  flake.modules.nixos.garage-migration-on-srv-prod-3 =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      sops.secrets."minio/global-read-user-access-key" = { };
      sops.secrets."minio/global-read-user-secret-key" = { };
      sops.secrets."garage/migration-user-key-id" = { };
      sops.secrets."garage/migration-user-secret-key" = { };
      sops.templates."rclone.conf" = {
        content = ''
          [minio]
          type = s3
          provider = Minio
          env_auth = false
          region = eu-central-1
          access_key_id = ${config.sops.placeholder."minio/global-read-user-access-key"}
          secret_access_key = ${config.sops.placeholder."minio/global-read-user-secret-key"}
          endpoint = https://localhost:9000
          location_constraint =
          server_side_encryption =

          [garage]
          type = s3
          provider = Other
          env_auth = false
          region = garage
          access_key_id = ${config.sops.placeholder."garage/migration-user-key-id"}
          secret_access_key = ${config.sops.placeholder."garage/migration-user-secret-key"}
          endpoint = http://localhost:3900
          location_constraint =
          server_side_encryption =
        '';
      };

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "rclone" ''
          exec ${lib.getExe pkgs.rclone} --config ${config.sops.templates."rclone.conf".path} "$@"
        '')
      ];
    };
}
