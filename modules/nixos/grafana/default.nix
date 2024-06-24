{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.grafana;
in {
  options.my.modules.grafana = {
    enable = lib.mkEnableOption "grafana";
  };

  config = lib.mkIf cfg.enable {
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

    # See https://wiki.nixos.org/wiki/Prometheus
    services.prometheus = {
      enable = true;
      # keep data for 90 days
      extraFlags = ["--storage.tsdb.retention.time=90d"];
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "localhost:9100"
                "${config.my.homelab.cyberoffice.ip}:9100"
                "${config.my.homelab.raspberry-pi.ip}:9100"
              ];
            }
          ];
        }
      ];
    };
  };
}
