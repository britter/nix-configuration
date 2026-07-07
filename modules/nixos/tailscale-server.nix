{ config, ... }:
let
  inherit (config.flake.modules.nixos) tailscale;
in
{
  flake.modules.nixos.tailscale-server =
    { config, ... }:
    {
      imports = [ tailscale ];

      sops.secrets."tailscale/auth-key" = { };
      services.tailscale.authKeyFile = config.sops.secrets."tailscale/auth-key".path;
    };
}
