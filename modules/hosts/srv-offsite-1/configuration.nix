{ inputs, config, ... }:
{
  flake.modules.nixos.srv-offsite-1 = {
    imports = [
      ../../../_needs_migration/modules
      inputs.nixos-facter-modules.nixosModules.facter
      config.flake.modules.nixos.system-base
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    facter.reportPath = ./facter.json;
    # see https://github.com/numtide/nixos-facter-modules/issues/62
    facter.detected.dhcp.enable = false;

    my = {
      host.role = "server";
      modules = {
        disko = {
          enable = true;
          bootDisk = "/dev/nvme0n1"; # 256GB
          storageDisk = "/dev/sda"; # 2TB
        };
        minio.enable = true;
        tailscale.enable = true;
      };
    };

    nixpkgs.config.permittedInsecurePackages = [
      "minio-2025-10-15T17-29-55Z"
    ];

    system.stateVersion = "25.05";
  };
}
