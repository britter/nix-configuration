_: {
  flake.modules.nixos.calibre-web =
    { config, ... }:
    let
      calibreLibraryPath = "/var/lib/calibre-library";
    in
    {
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

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "books.${config.networking.hostName}.ritter.family";
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
