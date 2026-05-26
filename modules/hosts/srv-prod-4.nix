{ config, ... }:
{
  flake.nixosConfigurations = config.flake.lib.mkNixosLegacy "x86_64-linux" "srv-prod-4";
}
