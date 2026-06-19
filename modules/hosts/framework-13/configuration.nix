{ config, ... }:
{
  flake.modules.nixos.framework-13 =
    {
      pkgs,
      ...
    }:
    {
      imports = with config.flake.modules.nixos; [
        system-desktop
        bene-on-framework-13
        gaming
      ];

      boot.kernelPackages = pkgs.linuxPackages_latest;

      services.fwupd.enable = true;

      services.printing.enable = true;
      services.avahi = {
        enable = true;
        # Enables mDNS NSS plugin for IPv4. Enabling it allows applications to resolve names in the .local domain
        # This is required for printing on a HP network printer
        nssmdns4 = true;
      };

      services.tailscale = {
        enable = true;
        extraSetFlags = [ "--accept-dns=false" ];
      };

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
    };
}
