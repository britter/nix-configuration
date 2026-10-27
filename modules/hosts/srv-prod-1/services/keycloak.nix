{ config, ... }:
let
  inherit (config.flake.modules.nixos) keycloak;
in
{
  flake.modules.nixos.keycloak-on-srv-prod-1 = {
    imports = [ keycloak ];
  };
}
