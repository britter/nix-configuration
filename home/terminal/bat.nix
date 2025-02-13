{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.terminal.bat;
in {
  options.my.home.terminal.bat = {
    enable = lib.mkEnableOption "bat";
  };

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        map-syntax = [
          "*.tofu:Terraform"
        ];
      };
    };
  };
}
