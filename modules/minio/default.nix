{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.minio;
in
{
  options.my.modules.minio = {
    enable = lib.mkEnableOption "minio";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."minio/root-user" = { };
    sops.secrets."minio/root-password" = { };
    sops.templates."minio-root-credentials" = {
      owner = "minio";
      content = ''
        MINIO_ROOT_USER=${config.sops.placeholder."minio/root-user"}
        MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/root-password"}
      '';
    };
    services.minio = {
      enable = true;
      region = "eu-central-1";
      rootCredentialsFile = config.sops.templates."minio-root-credentials".path;
    };
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."minio.${config.my.host.name}.ritter.family" = {
        useACMEHost = "minio.${config.my.host.name}.ritter.family";
        forceSSL = true;
        extraConfig = ''
          # Allow special characters in headers
          ignore_invalid_headers off;
          # Allow any size file to be uploaded.
          # Set to a value such as 1000m; to restrict file size to a specific value
          client_max_body_size 0;
          # Disable buffering
          proxy_buffering off;
          proxy_request_buffering off;
        '';
        locations = {
          "/" = {
            extraConfig = ''
              proxy_connect_timeout 300;
              # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
              proxy_http_version 1.1;
              proxy_set_header Connection "";
              chunked_transfer_encoding off;
            '';
            proxyPass = "http://localhost:9000";
          };
          "/minio/ui" = {
            extraConfig = ''
              rewrite ^/minio/ui/(.*) /$1 break;
              proxy_set_header X-NginX-Proxy true;

              # This is necessary to pass the correct IP to be hashed
              real_ip_header X-Real-IP;

              proxy_connect_timeout 300;

              # To support websockets in MinIO versions released after January 2023
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";

              chunked_transfer_encoding off;
            '';
            proxyPass = "http://localhost:9001";
          };
        };
      };
    };
    my.modules.acme.enable = true;
    security.acme.certs."minio.${config.my.host.name}.ritter.family" = { };
  };
}
