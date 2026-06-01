{ config, ... }:
{
  flake.modules.nixos.srv-prod-3 = {
    imports = [
      ../../../_needs_migration/modules
      config.flake.modules.nixos.system-base
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    my = {
      host.role = "server";
      modules = {
        proxmox-vm.enable = true;
        minio.enable = true;
        tailscale.enable = true;
      };
    };

    nixpkgs.config.permittedInsecurePackages = [
      "minio-2025-10-15T17-29-55Z"
    ];

    system.stateVersion = "24.05";
  };
}
