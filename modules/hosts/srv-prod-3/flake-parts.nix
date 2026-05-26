{ config, ... }:
{
  flake.nixosConfigurations = config.flake.lib.mkNixos "x86_64-linux" "srv-prod-3";
}
