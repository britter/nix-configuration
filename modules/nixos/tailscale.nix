_: {
  flake.modules.homeManager.tailscale = {
    services.trayscale.enable = true;
  };

  flake.modules.nixos.tailscale = {
    services.tailscale = {
      enable = true;
      extraSetFlags = [ "--accept-dns=false" ];
    };
  };
}
