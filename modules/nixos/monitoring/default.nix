{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.monitoring;
  homelabCfg = config.my.homelab;
in {
  options.my.modules.monitoring = {
    enable = lib.mkEnableOption "monitoring";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to option ports for the monitoring agents enabled by this module.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      inherit (cfg) openFirewall;
    };

    services.comin.exporter = {
      inherit (cfg) openFirewall;
    };

    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 8080;
          grpc_listen_port = 0;
        };
        clients = [
          {
            url = "http://${homelabCfg.watchtower.ip}:3100/loki/api/v1/push";
          }
        ];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.my.host.name;
              };
            };
            relabel_configs = [
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "unit";
              }
            ];
            pipeline_stages = [
              {
                match = {
                  selector = "{unit=\"nextcloud-cron.service\"}";
                  stages = [
                    {
                      json = {
                        expressions = {
                          level = "level";
                          timestamp = "time";
                          message = "message";
                          request_id = "reqId";
                          remote_address = "remoteAddr";
                          user = "user";
                          app = "app";
                          method = "method";
                          url = "url";
                          user_agent = "userAgent";
                          version = "version";
                          data = "data";
                        };
                      };
                    }
                    {
                      labels = {
                        level = "";
                        timestamp = "";
                        request_id = "";
                        remote_address = "";
                        user = "";
                        app = "";
                        method = "";
                        url = "";
                        user_agent = "";
                        version = "";
                        data = "";
                      };
                    }
                    {
                      output = {
                        source = "message";
                      };
                    }
                  ];
                };
              }
            ];
          }
        ];
      };
    };
  };
}
