{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.modules.my-user;
  myUser = config.my.user;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  options.my.modules.my-user = {
    enable = lib.mkEnableOption "my-user";
  };
  config = lib.mkIf cfg.enable {
    users.users.${myUser.name} = {
      isNormalUser = true;
      description = myUser.fullName;
      extraGroups = ["networkmanager" "wheel"];
      shell = pkgs.fish;
    };
    my.modules.home-manager.enable = true;
    # unfree packages used in home-manager configuration
    my.modules.allowedUnfreePkgs = [
      # Firefox browser extension
      "onepassword-password-manager"
    ];
  };
}
