{
  config,
  lib,
  ...
}: let
  cfg = config.my.home.terminal.direnv;
in {
  options.my.home.terminal.direnv = {
    enable = lib.mkEnableOption "direnv";
  };
  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        whitelist = {
          prefix = [
            "~/github/britter"
          ];
        };
      };
    };
  };
}
