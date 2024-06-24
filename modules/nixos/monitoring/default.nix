{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.monitoring;
in {
  options.my.modules.monitoring = {
    enable = lib.mkEnableOption "monitoring";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to option ports for the monitoring agents enabled by this module.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      inherit (cfg) openFirewall;
    };
  };
}
