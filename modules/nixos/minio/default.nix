{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.minio;
in {
  options.my.modules.minio = {
    enable = lib.mkEnableOption "minio";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."minio/root-user" = {};
    sops.secrets."minio/root-password" = {};
    sops.templates."minio-root-credentials.env" = {
      content = ''
        MINIO_ROOT_USER=${config.sops.placeholder."minio/root-user"}
        MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/root-password"}
      '';
      owner = "minio";
    };

    services.minio = {
      enable = true;
      rootCredentialsFile = config.sops.templates."minio-root-credentials.env".path;
    };

    networking.firewall.allowedTCPPorts = [9000 9001];
  };
}
