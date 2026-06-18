{ config, ... }:
{
  flake.modules.nixos.srv-prod-2 = {
    imports = with config.flake.modules.nixos; [
      system-server
      proxmox-vm
      git-server
      stirling-pdf
      tailscale
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    system.stateVersion = "23.11";
  };
}
