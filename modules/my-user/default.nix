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
    inputs.home-manager.nixosModules.home-manager
    ../common/home-manager
  ];
  config = {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.fullName;
      extraGroups = ["networkmanager" "wheel"];
      shell = pkgs.fish;
    };
    # unfree packages used in home-manager configuration
    my.modules.allowedUnfreePkgs = [
      "terraform"
    ];
  };
}
