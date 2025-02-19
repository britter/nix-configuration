{config, ...}: {
  imports = [
    ../../../modules
  ];

  my = {
    host = {
      role = "server";
    };
    modules = {
      proxmox-vm.enable = true;
      disko = {
        enable = true;
        bootDisk = "/dev/sda";
        storageDisk = "/dev/sdb";
      };
      app-sync = {
        enable = true;
        jobs = [
          {
            serviceName = "git";
            host = config.my.homelab.srv-prod-2.ip;
            dataDir = "/srv/git";
          }
          {
            serviceName = "calibre-web";
            host = config.my.homelab.srv-prod-2.ip;
            dataDir = "/var/lib/calibre-library";
          }
          {
            serviceName = "nextcloud";
            host = config.my.homelab.srv-prod-2.ip;
            dataDir = "/var/lib/nextcloud/data";
            preCommand = "nextcloud-occ maintenance:mode --on";
            postCommand = "nextcloud-occ maintenance:mode --off";
            runtimeInputs = [config.services.nextcloud.occ];
            databaseSync.enable = true;
          }
          {
            serviceName = "vaultwarden";
            host = config.my.homelab.srv-prod-2.ip;
            dataDir = "/var/lib/bitwarden_rs";
            preCommand = "systemctl stop vaultwarden";
            postCommand = "systemctl start vaultwarden";
            databaseSync.enable = true;
          }
        ];
      };
      git-server.enable = true;
      nextcloud = {
        enable = true;
        stage = "test";
      };
      calibre-web.enable = true;
      tailscale.enable = true;
      vaultwarden.enable = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
