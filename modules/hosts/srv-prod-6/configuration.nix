{ config, ... }:
{
  flake.modules.nixos.srv-prod-6 = {
    imports = with config.flake.modules.nixos; [
      system-server
      proxmox-vm
      tailscale
      beszel-agent
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
      (config.flake.factory.github-runners { count = 4; })
    ];

    system.stateVersion = "26.05";
  };
}
