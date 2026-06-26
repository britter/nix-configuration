{ config, ... }:
{
  flake.modules.nixos.srv-prod-1 = {
    imports = with config.flake.modules.nixos; [
      system-server
      proxmox-vm
      tailscale
      beszel-hub
      beszel-agent
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    system.stateVersion = "26.05";
  };
}
