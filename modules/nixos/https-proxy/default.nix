_: {
  flake.modules.nixos.https-proxy =
    { config, lib, ... }:
    let
      cfg = config.services.https-proxy;
      # Wildcard cert for this host, e.g. "*.srv-prod-2.ritter.family".
      # One cert for all services on the host: adding a service does
      # not require requesting a new certificate.
      wildcardDomain = "*.${config.networking.hostName}.${config.systemConstants.baseDomain}";
      wildcardDomains = [ wildcardDomain ] ++ cfg.extraWildcardDomains;
      # Wildcard certificates only match a single label, so
      # "*.a.b.c" covers "x.a.b.c" but not "x.y.a.b.c". Match a
      # config's fqdn by stripping its first label.
      #
      # The cert attribute name must not contain "*" (it ends up in
      # systemd unit names, and nixpkgs asserts against it); the
      # wildcard belongs in the cert's `domain` option instead.
      certName =
        wildcard: "wildcard." + lib.concatStringsSep "." (lib.drop 1 (lib.splitString "." wildcard));
      certFor =
        fqdn:
        let
          wildcard = "*." + lib.concatStringsSep "." (lib.drop 1 (lib.splitString "." fqdn));
        in
        if lib.elem wildcard wildcardDomains then
          certName wildcard
        else
          throw "https-proxy: no wildcard certificate covers ${fqdn} (requested: ${lib.concatStringsSep ", " wildcardDomains})";
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
          proxyHeaderBufferSize = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              proxy_buffer_size for backends that send large response
              headers (e.g. a big cookie bundle). Also pins
              proxy_busy_buffers_size to the same value: nginx derives its
              default busy size as twice this value, which fails nginx's
              "proxy_busy_buffers_size must be less than the size of all
              proxy_buffers minus one buffer" check against the default
              8x4k proxy_buffers when proxy_buffer_size is raised alone.
            '';
          };
        };
      });
    in
    {
      options.services.https-proxy = {
        enable = lib.mkEnableOption "https-proxy";
        extraWildcardDomains = lib.mkOption {
          type = lib.types.listOf (lib.types.strMatching "\\*\\..+");
          default = [ ];
          description = ''
            Additional wildcard domains to request certificates for,
            e.g. "*.example.com" for a proxy that serves names outside
            *.<host-name>.<baseDomain>.
          '';
        };
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
                  (lib.optionalString (conf.proxyHeaderBufferSize != null) ''
                    proxy_buffer_size ${conf.proxyHeaderBufferSize};
                    proxy_busy_buffers_size ${conf.proxyHeaderBufferSize};
                  '')
                  (lib.optionalString (!conf.buffering) "proxy_buffering off;\n")
                  conf.extraConfig
                ];
                serverAliases = conf.aliases;
                useACMEHost = certFor conf.fqdn;
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

        sops.secrets."cloudflare/api-token" = {
          sopsFile = ./secrets.yaml;
        };
        sops.secrets."inwx/username" = {
          sopsFile = ./secrets.yaml;
        };
        sops.secrets."inwx/password" = {
          sopsFile = ./secrets.yaml;
        };
        # only if the automation account has 2FA enabled:
        # sops.secrets."inwx/shared-secret" = {
        #   sopsFile = ./secrets.yaml;
        # };

        security.acme = {
          acceptTerms = true;
          defaults = {
            email = config.systemConstants.adminEmail;
            dnsProvider = "inwx";
            dnsPropagationCheck = true;
            credentialFiles = {
              "INWX_USERNAME_FILE" = config.sops.secrets."inwx/username".path;
              "INWX_PASSWORD_FILE" = config.sops.secrets."inwx/password".path;
              # only if the automation account has 2FA enabled:
              # "INWX_SHARED_SECRET_FILE" = config.sops.secrets."inwx/shared-secret".path;
              # keep until every cert has renewed once through INWX (rollback path):
              "CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare/api-token".path;
            };
          };
        };

        users.users.nginx.extraGroups = [ "acme" ];

        # One wildcard cert for the host itself, plus any extra
        # wildcards from extraWildcardDomains. All requested via
        # DNS-01 (see security.acme.defaults above), since wildcard
        # certs cannot be issued over HTTP.
        security.acme.certs = lib.listToAttrs (
          map (wildcard: lib.nameValuePair (certName wildcard) { domain = wildcard; }) wildcardDomains
        );
      };
    };
}
