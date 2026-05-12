{ config, ... }:
{
  flake.nixosConfigurations.srv-prod-4 = config.flake.lib.mkNixos "x86_64-linux" "srv-prod-4";
}
