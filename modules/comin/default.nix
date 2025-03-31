{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.modules.comin;
in
{
  imports = [
    inputs.comin.nixosModules.comin
  ];

  options.my.modules.comin = {
    enable = lib.mkEnableOption "comin";
  };

  config = lib.mkIf cfg.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/britter/nix-configuration.git";
        }
      ];
    };
  };
}
