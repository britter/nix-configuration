{ config, ... }:
{
  flake.homeConfigurations.benedikt = config.flake.lib.mkHomeManager "x86_64-linux" "benedikt" {
    osConfig.my.user = {
      fullName = "Benedikt Ritter";
      email = "benedikt.ritter@chainguard.dev";
      signingKey = "EA363E64382563CF";
    };
  };
}
