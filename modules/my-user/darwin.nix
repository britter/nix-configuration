{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.user;
in {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../common/home-manager
  ];
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "bene";
    };
  };
  config = {
    users.users.${cfg.name} = {
      name = cfg.name;
      home = "/Users/${cfg.name}";
      shell = pkgs.fish;
    };
  };
}
