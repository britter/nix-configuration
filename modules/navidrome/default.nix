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
      settings.MusicFolder = "/srv/navidrome-library";
    };

    my.modules.https-proxy = {
      enable = true;
      configurations = [
        {
          fqdn = "music.ritter.family";
          target = "http://localhost:4533";
        }
      ];
    };
  };
}
