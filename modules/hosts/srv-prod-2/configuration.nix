{ config, ... }:
{
  flake.modules.nixos.srv-prod-2 = {
    imports = with config.flake.modules.nixos; [
      ../../../_needs_migration/modules
      system-server
      proxmox-vm
      git-server
      tailscale
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    my.modules = {
      stirling-pdf.enable = true;
      vaultwarden.enable = true;
    };

    system.stateVersion = "23.11";
  };
}
