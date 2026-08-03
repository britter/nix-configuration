{ lib, ... }:
{
  options.flake.permittedInsecurePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Insecure package names permitted across all hosts and standalone home-manager configs.";
  };
}
