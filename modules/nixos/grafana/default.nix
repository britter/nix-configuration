{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.grafana;
in {
  imports = [
    ./prometheus.nix
  ];

  options.my.modules.grafana = {
    enable = lib.mkEnableOption "grafana";
  };

  config = lib.mkIf cfg.enable {
    my.modules.grafana.prometheus.enable = true;

    networking = {
      firewall = {
        allowedTCPPorts = [80 443 config.services.grafana.settings.server.http_port];
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts."grafana.ritter.family" = {
        serverAliases = ["grafana.*"];
        locations."/" = {
          proxyWebsockets = true;
          recommendedProxySettings = true;
          proxyPass = "http://localhost:3000";
        };
      };
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
  };
}
