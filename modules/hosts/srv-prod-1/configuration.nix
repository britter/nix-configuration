{ config, ... }:
{
  flake.modules.nixos.srv-prod-1 = {
    imports = with config.flake.modules.nixos; [
      system-server
      proxmox-vm
      tailscale-server
      beszel-agent
      keycloak-on-srv-prod-1
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    system.stateVersion = "26.05";
  };
}
