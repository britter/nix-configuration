{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.grafana;
in {
  imports = [
    ./loki.nix
    ./prometheus.nix
  ];

  options.my.modules.grafana = {
    enable = lib.mkEnableOption "grafana";
  };

  config = lib.mkIf cfg.enable {
    my.modules.grafana = {
      loki.enable = true;
      prometheus.enable = true;
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          domain = "grafana.ritter.family";
        };
      };
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Loki";
              type = "loki";
              uid = "Loki1";
              # TODO reference Loki service configuration
              url = "http://localhost:3100";
            }
            {
              name = "Prometheus";
              type = "prometheus";
              uid = "Prometheus1";
              # TODO reference prometheus service configuration
              url = "http://localhost:9090";
            }
          ];
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts."grafana.ritter.family" = {
        locations."/" = {
          proxyWebsockets = true;
          recommendedProxySettings = true;
          proxyPass = "http://localhost:3000";
        };
        useACMEHost = "grafana.ritter.family";
        forceSSL = true;
      };
    };

    security.acme.certs."grafana.ritter.family" = {};

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
