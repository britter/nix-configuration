{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.homepage;
in {
  options.my.modules.homepage = {
    enable = lib.mkEnableOption "homepage";
  };

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      widgets = [
        {
          resources = {
            cpu = true;
            disk = "/";
            memory = true;
          };
        }
        {
          search = {
            provider = "duckduckgo";
            target = "_blank";
          };
        }
      ];
      services = [
        {
          "Office" = [
            {
              "NextCloud" = {
                description = "Safe home for all out data";
                href = "http://nextcloud.ritter.family/";
                icon = "nextcloud-blue.svg";
              };
            }
          ];
        }
        {
          "Infrastructure" = [
            {
              "Proxmox" = {
                description = "Proxmox Virtual Environment";
                href = "https://proxmox.ritter.family/";
                icon = "proxmox.svg";
              };
            }
            {
              "Adguard" = {
                description = "Network-wide ads & trackers blocking DNS server";
                href = "https://adguard.ritter.family/";
                icon = "adguard-home.svg";
              };
            }
            {
              "FritzBox" = {
                description = "FritzBox Administration";
                href = "https://fritz-box.ritter.family/";
                icon = "avmfritzbox.svg";
              };
            }
          ];
        }
        {
          "Monitoring" = [
            {
              "Grafana" = {
                description = "Grafana Dashboards";
                href = "https://grafana.ritter.family/";
                icon = "grafana.svg";
              };
            }
          ];
        }
      ];
    };

    my.modules.https-proxy = {
      configurations = [
        {
          fqdn = "home.ritter.family";
          target = "http://localhost:8082";
        }
      ];
    };
  };
}
