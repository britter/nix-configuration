{ config, ... }:
{
  flake.nixosConfigurations.srv-prod-5 = config.flake.lib.mkNixos "x86_64-linux" "srv-prod-5";
}
