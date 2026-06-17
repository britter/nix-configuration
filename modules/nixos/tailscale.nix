_: {
  flake.modules.nixos.tailscale =
    { config, ... }:
    {
      sops.secrets."tailscale/auth-key" = { };

      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets."tailscale/auth-key".path;
        extraSetFlags = [ "--accept-dns=false" ];
      };
    };
}
