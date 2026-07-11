{ config, ... }:
{
  flake.modules.nixos.srv-prod-2 = {
    imports = with config.flake.modules.nixos; [
      system-server
      proxmox-vm
      stirling-pdf
      tailscale-server
      beszel-agent
      calibre-web-on-srv-prod-2
      git-server-on-srv-prod-2
      nextcloud-on-srv-prod-2
      paperless-on-srv-prod-2
      vaultwarden-on-srv-prod-2
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    system.stateVersion = "23.11";
  };
}
