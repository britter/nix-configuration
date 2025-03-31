{
  config,
  inputs,
  ...
}:
{
  imports = [
    ../../../modules
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  my = {
    host = {
      role = "server";
    };
    modules = {
      adguard.enable = true;
      homepage.enable = true;
      https-proxy = {
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
            target = "https://${config.my.homelab.fritz-box.ip}";
          }
          {
            fqdn = "grafana.ritter.family";
            target = "https://grafana.srv-prod-1.ritter.family";
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
            fqdn = "proxmox.ritter.family";
            target = "https://${config.my.homelab.proxmox.ip}:8006";
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
      tailscale.enable = true;
    };
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
