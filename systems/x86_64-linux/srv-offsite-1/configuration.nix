{ inputs, ... }:
{
  imports = [
    ../../../modules
    inputs.nixos-facter-modules.nixosModules.facter
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

  system.stateVersion = "25.05";
}
