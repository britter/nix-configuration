{ config, ... }:
{
  flake.modules.nixos.srv-prod-3 = {
    imports = with config.flake.modules.nixos; [
      system-server
      proxmox-vm
      tailscale
      beszel-agent
      minio
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    system.stateVersion = "24.05";
  };
}
