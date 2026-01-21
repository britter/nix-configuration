{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ../../../modules
  ];

  my = {
    host = {
      role = "desktop";
    };
    user.signingKey = "394546A47BB40E12";
    modules = {
      disko = {
        enable = true;
        bootDisk = "/dev/nvme0n1";
        swapSize = "64GB";
      };
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  facter.reportPath = ./facter.json;
  # see https://github.com/numtide/nixos-facter-modules/issues/62
  facter.detected.dhcp.enable = false;

  services.fwupd.enable = true;

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    # Enables mDNS NSS plugin for IPv4. Enabling it allows applications to resolve names in the .local domain
    # This is required for printing on a HP network printer
    nssmdns4 = true;
  };

  services.tailscale.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  environment.systemPackages = [
    pkgs.podman-compose
  ];
  programs.nix-ld.enable = true;

  system.stateVersion = "25.05";
}
