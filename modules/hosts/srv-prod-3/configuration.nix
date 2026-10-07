{ config, ... }:
{
  flake.modules.nixos.srv-prod-3 = {
    imports = with config.flake.modules.nixos; [
      system-server
      proxmox-vm
      tailscale-server
      beszel-agent
      minio
      garage-on-srv-prod-3
      garage-migration-on-srv-prod-3
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    system.stateVersion = "24.05";
  };
}
