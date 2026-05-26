{ config, ... }:
{
  flake.nixosConfigurations = config.flake.lib.mkNixosLegacy "x86_64-linux" "minimal-server-iso";
}
