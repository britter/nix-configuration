_: {
  flake.modules.nixos.https-proxy-on-directions =
    { config, ... }:
    {
      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "beszel.ritter.family";
            target = "https://beszel.srv-prod-1.ritter.family";
            proxyWebsockets = true;
          }
          {
            fqdn = "books.ritter.family";
            target = "https://books.srv-prod-2.ritter.family";
            maxBodySize = "512M";
          }
          {
            fqdn = "collabora.ritter.family";
            target = "https://collabora.srv-prod-2.ritter.family";
            proxyWebsockets = true;
          }
          {
            fqdn = "documents.ritter.family";
            target = "https://documents.srv-prod-2.ritter.family";
            maxBodySize = "100M";
          }
          {
            fqdn = "fritz-box.ritter.family";
            target = "https://${config.home-lab.devices.fritz-box.ip}";
          }
          {
            fqdn = "git.ritter.family";
            target = "https://git.srv-prod-6.ritter.family";
            maxBodySize = "512M";
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
            maxBodySize = "512M";
          }
          {
            fqdn = "photos.ritter.family";
            target = "https://photos.srv-prod-4.ritter.family";
            proxyWebsockets = true;
            maxBodySize = "50000M";
            proxyTimeout = "600s";
          }
          {
            fqdn = "pve.ritter.family";
            target = "https://${config.home-lab.hypervisors.pve.ip}:8006";
            # Avoid buffering issues with the Proxmox task log stream
            buffering = false;
            proxyTimeout = "3600s";
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
          {
            fqdn = "tools.ritter.family";
            target = "https://tools.srv-prod-6.ritter.family";
          }
          {
            fqdn = "unifi.ritter.family";
            target = "https://192.168.1.1";
            proxyWebsockets = true;
          }
        ];
      };
    };
}
