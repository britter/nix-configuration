_: {
  flake.modules.nixos.printing = {
    services.printing.enable = true;
    services.avahi = {
      enable = true;
      # Enables mDNS NSS plugin for IPv4. Enabling it allows applications to resolve names in the .local domain
      # This is required for printing on a HP network printer
      nssmdns4 = true;
    };
  };
}
