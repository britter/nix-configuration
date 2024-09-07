{
  config,
  inputs,
  ...
}: {
  imports = [
    ../../../modules/nixos
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
            fqdn = "fritz-box.ritter.family";
            target = "https://${config.my.homelab.fritz-box.ip}";
          }
          {
            fqdn = "nextcloud.ritter.family";
            target = "https://nextcloud.srv-prod-2.ritter.family";
          }
          {
            fqdn = "proxmox.ritter.family";
            target = "https://${config.my.homelab.proxmox.ip}:8006";
          }
        ];
      };
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
