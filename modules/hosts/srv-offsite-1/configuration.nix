{ config, ... }:
{
  flake.modules.nixos.srv-offsite-1 = {
    imports = with config.flake.modules.nixos; [
      ../../../_needs_migration/modules
      system-server
      tailscale
      minio-sync-on-srv-offsite-1
      weekly-update-window-on-srv-offsite-1
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    my.modules = {
      minio.enable = true;
    };

    nixpkgs.config.permittedInsecurePackages = [
      "minio-2025-10-15T17-29-55Z"
    ];

    system.stateVersion = "25.05";
  };
}
