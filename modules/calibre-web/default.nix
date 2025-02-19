{
  config,
  lib,
  ...
}: let
  cfg = config.my.modules.calibre-web;
in {
  options.my.modules.calibre-web = {
    enable = lib.mkEnableOption "calibre-web";
  };

  config = lib.mkIf cfg.enable {
    services.calibre-web = {
      enable = true;
      listen.ip = "0.0.0.0";
      options = {
        enableBookConversion = true;
        enableBookUploading = true;
        enableKepubify = true;
      };
    };

    my.modules.https-proxy = {
      configurations = [
        {
          fqdn = "books.${config.my.host.name}.ritter.family";
          aliases = ["books.ritter.family"];
          target = "http://localhost:8083";
        }
      ];
    };
  };
}
