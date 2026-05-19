{
  config,
  lib,
  ...
}:
let
  cfg = config.my.modules.calibre-web;
in
{
  options.my.modules.calibre-web = {
    enable = lib.mkEnableOption "calibre-web";
  };

  config =
    let
      calibreLibraryPath = "/var/lib/calibre-library";
    in
    lib.mkIf cfg.enable {
      services.calibre-web = {
        enable = true;
        listen.ip = "0.0.0.0";
        options = {
          enableBookConversion = true;
          enableBookUploading = true;
          enableKepubify = true;
          calibreLibrary = calibreLibraryPath;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${calibreLibraryPath} 0755 calibre-web calibre-web"
      ];

      my.modules.https-proxy = {
        configurations = [
          {
            fqdn = "books.${config.my.host.name}.ritter.family";
            aliases = [ "books.ritter.family" ];
            target = "http://localhost:8083";
            extraConfig = ''
              client_max_body_size 100M;
            '';
          }
        ];
      };
    };
}
