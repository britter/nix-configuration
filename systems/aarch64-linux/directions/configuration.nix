{
  pkgs,
  inputs,
  home-lab,
  ...
}:
{
  imports = [
    ../../../modules
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  # workaround for https://github.com/NixOS/nixos-hardware/commit/c8f766fd11c8b0a9832b6ca1819de74fbfee3d73
  # the Raspberry Pi kernel is about to be removed from nixpkgs, so the aforementioned commit adds
  # a custom derivation that builds it from scratch. Since nixos-hardware does not have a binary
  # cache is causes a kernel rebuild on this machine, which takes very long.
  # See also https://github.com/NixOS/nixos-hardware/issues/325#issuecomment-4199711155
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

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
            target = "https://${home-lab.devices.fritz-box.ip}";
          }
          {
            fqdn = "grafana.ritter.family";
            target = "https://grafana.srv-prod-1.ritter.family";
          }
          {
            fqdn = "homeassistant.ritter.family";
            target = "http://${home-lab.hosts.home-assistant.ip}:8123";
            proxyWebsockets = true;
          }
          {
            fqdn = "jetkvm.ritter.family";
            target = "https://${home-lab.devices.jetkvm.ip}";
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
            target = "https://${home-lab.hypervisors.pve.ip}:8006";
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
