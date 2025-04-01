{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.grafana;
in
{
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
          domain = "grafana.${config.my.host.name}.ritter.family";
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
              url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
            }
            {
              name = "Prometheus";
              type = "prometheus";
              uid = "Prometheus1";
              url = "http://localhost:${toString config.services.prometheus.port}";
            }
          ];
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "dashboards";
              options.path = ./dashboards;
              options.foldersFromFilesStructure = true;
            }
          ];
        };
      };
    };

    my.modules.https-proxy = {
      enable = true;
      configurations = [
        {
          fqdn = "grafana.${config.my.host.name}.ritter.family";
          aliases = [ "grafana.ritter.family" ];
          target = "http://localhost:3000";
          proxyWebsockets = true;
        }
      ];
    };
  };
}
