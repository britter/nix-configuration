{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.grafana.prometheus;
in
{
  options.my.modules.grafana.prometheus = {
    enable = lib.mkEnableOption "prometheus";
  };
  config = lib.mkIf cfg.enable {
    # See https://wiki.nixos.org/wiki/Prometheus
    services.prometheus = {
      enable = true;
      # keep data for 90 days
      extraFlags = [ "--storage.tsdb.retention.time=90d" ];
      scrapeConfigs =
        let
          allHosts = [
            "directions"
            "srv-prod-1"
            "srv-prod-2"
            "srv-test-1"
            "srv-test-2"
            "srv-eval-1"
            "srv-backup-1"
          ];
        in
        [
          {
            job_name = "node";
            static_configs = [
              {
                targets = lib.map (h: "${h}.ritter.family:9100") allHosts;
              }
            ];
          }
          {
            job_name = "comin";
            static_configs = [
              {
                targets = lib.map (h: "${h}.ritter.family:4243") allHosts;
              }
            ];
          }
        ];
    };
  };
}
