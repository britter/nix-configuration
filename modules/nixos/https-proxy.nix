_: {
  flake.modules.nixos.https-proxy =
    { config, lib, ... }:
    let
      cfg = config.services.https-proxy;
      proxyConfig = lib.types.submodule (_: {
        options = {
          fqdn = lib.mkOption {
            type = lib.types.str;
          };
          aliases = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          target = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          proxyWebsockets = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          maxBodySize = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''client_max_body_size value, e.g. "512M" or "0" for unlimited.'';
          };
          proxyTimeout = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''Sets proxy_read_timeout, proxy_send_timeout and send_timeout, e.g. "600s".'';
          };
          buffering = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "When false, disables proxy_buffering (for streaming backends).";
          };
          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
          };
        };
      });
    in
    {
      options.services.https-proxy = {
        enable = lib.mkEnableOption "https-proxy";
        configurations = lib.mkOption {
          type = lib.types.listOf proxyConfig;
          default = [ ];
        };
      };

      config = lib.mkIf cfg.enable {
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        services.nginx.enable = true;
        services.nginx.virtualHosts =
          let
            makeHost = conf: {
              ${conf.fqdn} = {
                extraConfig = lib.concatStrings [
                  (lib.optionalString (conf.maxBodySize != null) "client_max_body_size ${conf.maxBodySize};\n")
                  (lib.optionalString (conf.proxyTimeout != null) ''
                    proxy_read_timeout ${conf.proxyTimeout};
                    proxy_send_timeout ${conf.proxyTimeout};
                    send_timeout ${conf.proxyTimeout};
                  '')
                  (lib.optionalString (!conf.buffering) "proxy_buffering off;\n")
                  conf.extraConfig
                ];
                serverAliases = conf.aliases;
                useACMEHost = conf.fqdn;
                forceSSL = true;
              }
              // lib.optionalAttrs (conf.target != null) {
                locations."/" = {
                  inherit (conf) proxyWebsockets;
                  recommendedProxySettings = true;
                  proxyPass = conf.target;
                };
              };
            };
          in
          lib.mkMerge (lib.map makeHost cfg.configurations);

        sops.secrets."acme/cloudflare-dns-api-token" = { };

        security.acme = {
          acceptTerms = true;
          defaults = {
            email = config.systemConstants.adminEmail;
            dnsProvider = "cloudflare";
            dnsPropagationCheck = true;
            credentialFiles = {
              "CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."acme/cloudflare-dns-api-token".path;
            };
          };
        };

        users.users.nginx.extraGroups = [ "acme" ];

        security.acme.certs =
          let
            makeCert = conf: {
              ${conf.fqdn} = { };
            };
          in
          lib.mkMerge (lib.map makeCert cfg.configurations);
      };
    };
}
