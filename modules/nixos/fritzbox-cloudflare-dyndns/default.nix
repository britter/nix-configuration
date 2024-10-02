{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.fritzbox-cloudflare-dyndns;
in {
  options.services.fritzbox-cloudflare-dyndns = {
    enable = lib.mkEnableOption "fritzbox-cloudflare-dyndns";
    package = lib.mkPackageOption pkgs "fritzbox-cloudflare-dyndns" {};
    environmentFile = lib.mkOption {
      type = lib.types.path;
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.fritzbox-cloudflare-dyndns = {
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        EnvironmentFile = cfg.environmentFile;
        ExecStart = "${cfg.package}/bin/fritzbox-cloudflare-dyndns";
        Type = "simple";
        User = "fritzbox-cloudflare-dyndns";
      };
    };
    users.users.fritzbox-cloudflare-dyndns = {
      isSystemUser = true;
      group = "fritzbox-cloudflare-dyndns";
    };
    users.groups.fritzbox-cloudflare-dyndns = {};
  };
}
