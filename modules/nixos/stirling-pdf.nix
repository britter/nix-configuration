_: {
  flake.modules.nixos.stirling-pdf =
    { config, pkgs, ... }:
    let
      deu-traineddata = pkgs.fetchurl {
        url = "https://github.com/tesseract-ocr/tessdata/raw/refs/heads/main/deu.traineddata";
        hash = "sha256-iWs7SVZQOrnaoQKF2zMIgbLXS3DYibeSYsxTS57GmaQ=";
      };
    in
    {
      services.stirling-pdf = {
        enable = true;
        environment = {
          INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
          SYSTEM_ENABLEANALYTICS = "false";
          SERVER_PORT = 8090;
        };
      };

      systemd.tmpfiles.rules = [
        "d /usr/share/tessdata 0755 root root"
        "L+ /usr/share/tessdata/deu.traineddata - - - - ${deu-traineddata}"
      ];

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "pdf.${config.networking.hostName}.ritter.family";
            aliases = [ "pdf.ritter.family" ];
            target = "http://localhost:8090";
            extraConfig = ''
              client_max_body_size 100M;
            '';
          }
        ];
      };
    };
}
