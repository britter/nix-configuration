{ config, ... }:
{
  flake.modules.nixos.srv-offsite-1 = {
    imports = [
      ../../../_needs_migration/modules
      config.flake.modules.nixos.system-server
      config.flake.modules.nixos.tailscale
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
