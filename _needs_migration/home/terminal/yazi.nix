{
  config,
  lib,
  ...
}:
let
  cfg = config.my.home.terminal.yazi;
in
{
  options.my.home.terminal.yazi = {
    enable = lib.mkEnableOption "yazi";
  };
  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      # default for stateVersion >= 26.05
      shellWrapperName = "y";
    };
  };
}
