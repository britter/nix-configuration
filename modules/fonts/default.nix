{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.modules.fonts;
in
{
  options.my.modules.fonts = {
    enable = lib.mkEnableOption "fonts";
    fonts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "FiraCode" ];
    };
  };
  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      font-awesome
      (nerdfonts.override { inherit (cfg) fonts; })
    ];
  };
}
