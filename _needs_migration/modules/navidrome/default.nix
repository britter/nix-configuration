{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.navidrome;
in
{
  options.my.modules.navidrome = {
    enable = lib.mkEnableOption "default";
  };

  config = lib.mkIf cfg.enable {
    services.navidrome = {
      enable = true;
      settings.EnableInsightsCollector = false;
    };

    my.modules.https-proxy = {
      enable = true;
      configurations = [
        {
          fqdn = "music.${config.networking.hostName}.ritter.family";
          target = "http://localhost:4533";
        }
      ];
    };
  };
}
