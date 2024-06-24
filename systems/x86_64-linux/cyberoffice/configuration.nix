{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../../modules/nixos
    inputs.sops-nix.nixosModules.sops
  ];

  my = {
    host = {
      name = "cyberoffice";
      system = "x86_64-linux";
      role = "server";
    };
    modules = {
      disko = {
        enable = true;
        disk = "/dev/sda";
      };
    };
  };

  # TODO extract into a VM module
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
  services.qemuGuest.enable = true;

  networking = {
    firewall = {
      allowedTCPPorts = [80 443];
    };
  };

  sops.defaultSopsFile = ./secrets.yaml;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  sops.secrets.nextcloud-admin-pass = {
    owner = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "nextcloud.ritter.family";
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) bookmarks calendar contacts cookbook deck memories richdocuments;
      news = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha7/news.tar.gz";
        sha256 = "sha256-XNGjf7SWgJYFdVNOh3ED0jxSG0GJwWImVQq4cJT1Lo4=";
        license = "agpl3Plus";
      };
    };
    extraAppsEnable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}