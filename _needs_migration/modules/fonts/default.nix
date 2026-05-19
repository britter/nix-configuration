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
      default = [ "fira-code" ];
    };
  };
  config = lib.mkIf cfg.enable {
    fonts.packages = [
      pkgs.font-awesome
    ]
    ++ (lib.map (font: pkgs.nerd-fonts."${font}") cfg.fonts);
  };
}
