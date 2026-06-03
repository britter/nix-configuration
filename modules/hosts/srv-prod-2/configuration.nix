{ config, ... }:
{
  flake.modules.nixos.srv-prod-2 = {
    imports = with config.flake.modules.nixos; [
      ../../../_needs_migration/modules
      system-server
      proxmox-vm
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    my.modules = {
      git-server.enable = true;
      nextcloud = {
        enable = true;
        stage = "production";
      };
      calibre-web.enable = true;
      stirling-pdf.enable = true;
      tailscale.enable = true;
      vaultwarden.enable = true;
    };

    boot.supportedFilesystems = [ "nfs" ];
    fileSystems."/srv/nextcloud-data" = {
      fsType = "nfs";
      device = "storage.ritter.family:/mnt/default-pool/nextcloud";
    };

    systemd.services.nginx = {
      unitConfig = {
        RequiresMountsFor = "/srv/nextcloud-data";
      };
    };
    services.nextcloud.settings.datadirectory = "/srv/nextcloud-data";

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.11"; # Did you read the comment?
  };
}
