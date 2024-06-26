{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.grafana.prometheus;
in {
  options.my.modules.grafana.prometheus = {
    enable = lib.mkEnableOption "prometheus";
  };
  config = lib.mkIf cfg.enable {
    # See https://wiki.nixos.org/wiki/Prometheus
    services.prometheus = {
      enable = true;
      # keep data for 90 days
      extraFlags = ["--storage.tsdb.retention.time=90d"];
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "localhost:9100"
                "${config.my.homelab.cyberoffice.ip}:9100"
                "${config.my.homelab.raspberry-pi.ip}:9100"
              ];
            }
          ];
        }
        {
          job_name = "comin";
          static_configs = [
            {
              targets = [
                "localhost:4243"
                "${config.my.homelab.cyberoffice.ip}:4243"
                "${config.my.homelab.raspberry-pi.ip}:4243"
              ];
            }
          ];
        }
      ];
    };
  };
}
