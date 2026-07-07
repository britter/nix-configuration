{ config, ... }:
{
  flake.modules.nixos.srv-offsite-1 = {
    imports = with config.flake.modules.nixos; [
      system-server
      tailscale-server
      minio
      minio-sync-on-srv-offsite-1
      weekly-update-window-on-srv-offsite-1
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    system.stateVersion = "25.05";
  };
}
