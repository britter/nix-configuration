{
  inputs,
  ...
}: {
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
        bootDisk = "/dev/sdb"; # 256GB
        storageDisk = "/dev/sda"; # 2TB
      };
      tailscale.enable = true;
    };
  };

  users.users.backup = {
    isSystemUser = true;
    group = "backup";
    description = "Backup user";
    home = "/var/backups";
    createHome = true;
    openssh.authorizedKeys.keyFiles = [../srv-prod-2/ssh_srv-prod-2_ed25519_key.pub];
  };
  users.groups.backup = {};

  # Configure SFTP-Only Access for backup user
  services.openssh.extraConfig = ''
    Match User backup
    ForceCommand internal-sftp
    ChrootDirectory /var/backups
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
  '';

  system.stateVersion = "24.11";
}
