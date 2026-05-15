{ config, ... }:
{
  flake.nixosConfigurations.srv-offsite-1 = config.flake.lib.mkNixos "x86_64-linux" "srv-offsite-1";
}
