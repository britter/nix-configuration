{ config, ... }:
{
  flake.nixosConfigurations.directions = config.flake.lib.mkNixos "aarch64-linux" "directions";
}
