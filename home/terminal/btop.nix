{
  config,
  lib,
  ...
}:
let
  cfg = config.my.home.terminal.btop;
in
{
  options.my.home.terminal.btop = {
    enable = lib.mkEnableOption "btop";
  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;
    };

    # required for catppuccin theming of btop
    xdg.enable = true;
  };
}
