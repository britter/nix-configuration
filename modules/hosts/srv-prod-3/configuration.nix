{ config, ... }:
{
  flake.modules.nixos.srv-prod-3 = {
    imports = with config.flake.modules.nixos; [
      ../../../_needs_migration/modules
      system-server
      proxmox-vm
      tailscale
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    my.modules = {
      minio.enable = true;
    };

    nixpkgs.config.permittedInsecurePackages = [
      "minio-2025-10-15T17-29-55Z"
    ];

    system.stateVersion = "24.05";
  };
}
