_: {
  flake.modules.nixos.navidrome =
    { config, ... }:
    {
      services.navidrome = {
        enable = true;
        settings.EnableInsightsCollector = false;
      };

      services.https-proxy = {
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
