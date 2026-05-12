{ config, ... }:
{
  flake.nixosConfigurations.srv-prod-2 = config.flake.lib.mkNixos "x86_64-linux" "srv-prod-2";
}
