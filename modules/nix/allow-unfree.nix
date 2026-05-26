{ lib, ... }:
{
  options.flake.allowUnfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Unfree package names allowed across all hosts and standalone home-manager configs.";
  };
}
