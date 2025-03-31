{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.i18n;
in
{
  options.my.modules.i18n = {
    enable = lib.mkEnableOption "i18n";
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Berlin";
    };
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
    };
    extraLocale = lib.mkOption {
      type = lib.types.str;
      default = "de_DE.UTF-8";
    };
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.timeZone;
    i18n.defaultLocale = cfg.defaultLocale;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = cfg.extraLocale;
      LC_IDENTIFICATION = cfg.extraLocale;
      LC_MEASUREMENT = cfg.extraLocale;
      LC_MONETARY = cfg.extraLocale;
      LC_NAME = cfg.extraLocale;
      LC_NUMERIC = cfg.extraLocale;
      LC_PAPER = cfg.extraLocale;
      LC_TELEPHONE = cfg.extraLocale;
      LC_TIME = cfg.extraLocale;
    };
  };
}
