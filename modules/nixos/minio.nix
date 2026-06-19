_: {
  flake.modules.nixos.minio =
    { config, ... }:
    let
      fqdn = "minio.${config.networking.hostName}.ritter.family";
    in
    {
      sops.secrets."minio/root-user" = { };
      sops.secrets."minio/root-password" = { };
      sops.templates."minio-root-credentials" = {
        owner = "minio";
        content = ''
          MINIO_ROOT_USER=${config.sops.placeholder."minio/root-user"}
          MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/root-password"}
        '';
      };

      nixpkgs.config.permittedInsecurePackages = [
        "minio-2025-10-15T17-29-55Z"
      ];

      services.minio = {
        enable = true;
        region = "eu-central-1";
        rootCredentialsFile = config.sops.templates."minio-root-credentials".path;
      };
      systemd.services.minio.environment = {
        MINIO_BROWSER_REDIRECT_URL = "https://${fqdn}/console/";
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            inherit fqdn;
            target = "http://localhost:9000";
            proxyWebsockets = true;
            extraConfig = ''
              # Allow special characters in headers
              ignore_invalid_headers off;
              # Allow any size file to be uploaded.
              # Set to a value such as 1000m; to restrict file size to a specific value
              client_max_body_size 0;
              # Disable buffering
              proxy_buffering off;
              proxy_request_buffering off;
              proxy_connect_timeout 300;
              chunked_transfer_encoding off;
            '';
          }
        ];
      };

      # The minio console runs on a separate port and needs its own location
      # block — https-proxy only generates `/`, so we add /console/ directly.
      services.nginx.virtualHosts.${fqdn}.locations."/console/" = {
        extraConfig = ''
          proxy_set_header X-NginX-Proxy true;
          # This is necessary to pass the correct IP to be hashed
          real_ip_header X-Real-IP;
        '';
        proxyPass = "http://localhost:9001/";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
}
