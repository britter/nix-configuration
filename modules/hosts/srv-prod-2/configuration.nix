{ config, ... }:
{
  flake.modules.nixos.srv-prod-2 = {
    imports = with config.flake.modules.nixos; [
      ../../../_needs_migration/modules
      system-server
      proxmox-vm
      git-server
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    my.modules = {
      nextcloud = {
        enable = false;
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

    system.stateVersion = "23.11";
  };
}
