_: {
  flake.modules.nixos.garage =
    { config, pkgs, ... }:
    let
      fqdn = "garage.${config.networking.hostName}.ritter.family";
    in
    {
      sops.secrets."garage/rpc-secret" = { };
      sops.secrets."garage/admin-token" = { };
      sops.templates."garage/env" = {
        content = ''
          GARAGE_RPC_SECRET=${config.sops.placeholder."garage/rpc-secret"}
          GARAGE_ADMIN_TOKEN=${config.sops.placeholder."garage/admin-token"}
        '';
      };

      services.garage = {
        enable = true;
        package = pkgs.garage_2;
        environmentFile = config.sops.templates."garage/env".path;
        settings = {
          replication_factor = 1;
          rpc_bind_addr = "[::1]:3901";
          rpc_public_addr = "[::1]:3901";
          s3_api = {
            s3_region = "garage";
            api_bind_addr = "[::1]:3900";
          };
          admin = {
            api_bind_addr = "[::1]:3903";
          };
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            inherit fqdn;
            target = "http://localhost:3900";
            # Allow any size file to be uploaded.
            maxBodySize = "0";
            buffering = false;
            extraConfig = ''
              proxy_request_buffering off;
              proxy_connect_timeout 300;
              chunked_transfer_encoding off;
            '';
          }
        ];
      };

      # Expose the admin /health endpoint so gatus can monitor the S3 vhost,
      # plus the admin API v2 (all Garage operations live under /v2/) for
      # remote management via scoped bearer tokens.
      services.nginx.virtualHosts.${fqdn} = {
        locations."= /health" = {
          proxyPass = "http://localhost:3903/health";
          recommendedProxySettings = true;
        };
        locations."/v2/" = {
          proxyPass = "http://localhost:3903";
          recommendedProxySettings = true;
        };
      };
    };
}
