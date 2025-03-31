{
  config,
  lib,
  ...
}:
let
  cfg = config.my.home.desktop.ghostty;
in
{
  options.my.home.desktop.ghostty = {
    enable = lib.mkEnableOption "ghostty";
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        confirm-close-surface = false;
      };
    };
  };
}
