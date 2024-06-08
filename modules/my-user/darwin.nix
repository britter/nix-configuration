{
  config,
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

  config = {
    users.users.${cfg.name} = {
      inherit (cfg) name;
      home = "/Users/${cfg.name}";
      shell = pkgs.fish;
    };
    my.modules.home-manager.enable = true;
  };
}
