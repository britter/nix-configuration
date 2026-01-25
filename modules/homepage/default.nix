{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.homepage;
in
{
  options.my.modules.homepage = {
    enable = lib.mkEnableOption "homepage";
  };

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      settings = {
        background = {
          image = "https://images.unsplash.com/photo-1502790671504-542ad42d5189?auto=format&fit=crop&w=2560&q=80";
          blur = "sm";
          saturate = 50;
          brightness = 50;
          opacity = 50;
        };
      };
      allowedHosts = "localhost:8082,127.0.0.1:8082,home.ritter.family";
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
      # see https://gethomepage.dev/configs/services/#icons for how to set icons
      services = [
        {
          "Office" = [
            {
              "NextCloud" = {
                description = "Safe home for all our data";
                href = "https://nextcloud.ritter.family/";
                icon = "nextcloud-blue.svg";
              };
            }
            {
              "Stirling PDF" = {
                description = "Web application that allows you to perform various operations on PDF files";
                href = "https://pdf.ritter.family/";
                icon = "stirling-pdf.svg";
              };
            }
            {
              "Vaultwarden" = {
                description = "Password safe";
                href = "https://passwords.ritter.family/";
                icon = "vaultwarden.svg";
              };
            }
          ];
        }
        {
          "Media" = [
            {
              "Calibre Web" = {
                description = "App for browsing, reading and downloading eBooks";
                href = "https://books.ritter.family";
                icon = "calibre-web.svg";
              };
            }
          ];
        }
        {
          "Smart Home" = [
            {
              "Home Assistant" = {
                description = "Open source home automation that puts local control and privacy first.";
                href = "https://homeassistant.ritter.family/";
                icon = "homeassistant.svg";
              };
            }
          ];
        }
        {
          "Infrastructure" = [
            {
              "UniFi" = {
                description = "UniFi Network Configuration";
                href = "https://192.168.1.1";
                icon = "unifi.svg";
              };
            }
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
