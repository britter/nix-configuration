{ config, ... }:
{
  flake.nixosConfigurations = config.flake.lib.mkNixosLegacy "aarch64-linux" "directions";
}
