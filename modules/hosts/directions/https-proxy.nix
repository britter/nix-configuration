_: {
  flake.modules.nixos.directions =
    { config, ... }:
    {
      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "books.ritter.family";
            target = "https://books.srv-prod-2.ritter.family";
            extraConfig = ''
              client_max_body_size 512M;
            '';
          }
          {
            fqdn = "collabora.ritter.family";
            target = "https://collabora.srv-prod-2.ritter.family";
            proxyWebsockets = true;
          }
          {
            fqdn = "collabora-test.ritter.family";
            target = "https://collabora.srv-test-2.ritter.family";
            proxyWebsockets = true;
          }
          {
            fqdn = "fritz-box.ritter.family";
            target = "https://${config.home-lab.devices.fritz-box.ip}";
          }
          {
            fqdn = "grafana.ritter.family";
            target = "https://grafana.srv-prod-1.ritter.family";
          }
          {
            fqdn = "homeassistant.ritter.family";
            target = "http://${config.home-lab.hosts.home-assistant.ip}:8123";
            proxyWebsockets = true;
          }
          {
            fqdn = "jetkvm.ritter.family";
            target = "https://${config.home-lab.devices.jetkvm.ip}";
            proxyWebsockets = true;
          }
          {
            fqdn = "music.ritter.family";
            target = "https://music.srv-prod-5.ritter.family";
          }
          {
            fqdn = "nextcloud.ritter.family";
            target = "https://nextcloud.srv-prod-2.ritter.family";
            extraConfig = ''
              client_max_body_size 512M;
            '';
          }
          {
            fqdn = "nextcloud-test.ritter.family";
            target = "https://nextcloud.srv-test-2.ritter.family";
            extraConfig = ''
              client_max_body_size 512M;
            '';
          }
          {
            fqdn = "photos.ritter.family";
            target = "https://photos.srv-prod-4.ritter.family";
            proxyWebsockets = true;
            extraConfig = ''
              client_max_body_size 50000M;
              proxy_read_timeout   600s;
              proxy_send_timeout   600s;
              send_timeout         600s;
            '';
          }
          {
            fqdn = "pve.ritter.family";
            target = "https://${config.home-lab.hypervisors.pve.ip}:8006";
          }
          {
            fqdn = "passwords.ritter.family";
            target = "https://passwords.srv-prod-2.ritter.family";
          }
          {
            fqdn = "pdf.ritter.family";
            target = "https://pdf.srv-prod-2.ritter.family";
            extraConfig = ''
              client_max_body_size 100M;
            '';
          }
        ];
      };
    };
}
