{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules._1password;
in {
  options.my.modules._1password = {
    enable = lib.mkEnableOption "1Password";
  };

  config = lib.mkIf cfg.enable {
    programs._1password-gui.enable = true;

    my.modules.allowedUnfreePkgs = ["1password"];
  };
}
