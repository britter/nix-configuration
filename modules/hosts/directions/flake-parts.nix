{ config, ... }:
{
  flake.nixosConfigurations = config.flake.lib.mkNixos "aarch64-linux" "directions";
}
