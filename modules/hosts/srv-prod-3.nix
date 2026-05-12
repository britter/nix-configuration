{ config, ... }:
{
  flake.nixosConfigurations.srv-prod-3 = config.flake.lib.mkNixos "x86_64-linux" "srv-prod-3";
}
