{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.grafana.loki;
in {
  options.my.modules.grafana.loki = {
    enable = lib.mkEnableOption "loki";
  };
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [config.services.loki.configuration.server.http_listen_port];

    # This is extracted from various sources, including:
    # https://github.com/mrVanDalo/nix-nomad-cluster/blob/6a605c89dc25cada4c59beea864e9bae150b8eea/nixos/roles/monitor/loki.nix
    # https://grafana.com/blog/2019/08/22/homelab-security-with-ossec-loki-prometheus-and-grafana-on-a-raspberry-pi/
    # https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20/
    # https://grafana.com/docs/loki/latest/configure
    services.loki = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3100;
        };
        auth_enabled = false;

        analytics = {
          reporting_enabled = false;
        };

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
        };

        schema_config = {
          configs = [
            {
              from = "2024-06-24";
              store = "boltdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "168h"; # seven days
              };
            }
          ];
        };

        storage_config = {
          boltdb = {
            directory = "/var/lib/loki/index";
          };
          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        limits_config = {
          allow_structured_metadata = false;
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        table_manager = {
          chunk_tables_provisioning = {
            inactive_read_throughput = 0;
            inactive_write_throughput = 0;
            provisioned_read_throughput = 0;
            provisioned_write_throughput = 0;
          };
          index_tables_provisioning = {
            inactive_read_throughput = 0;
            inactive_write_throughput = 0;
            provisioned_read_throughput = 0;
            provisioned_write_throughput = 0;
          };
          retention_deletes_enabled = true;
          retention_period = "720h"; # 30 days
        };
      };
    };
  };
}
