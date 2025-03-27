{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.modules.stirling-pdf;
in {
  options.my.modules.stirling-pdf = {
    enable = lib.mkEnableOption "stirling-pdf";
  };

  config = let
    deu-traineddata = pkgs.fetchurl {
      url = "https://github.com/tesseract-ocr/tessdata/raw/refs/heads/main/deu.traineddata";
      hash = "sha256-iWs7SVZQOrnaoQKF2zMIgbLXS3DYibeSYsxTS57GmaQ=";
    };
  in
    lib.mkIf cfg.enable {
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

      my.modules.https-proxy = {
        configurations = [
          {
            fqdn = "pdf.${config.my.host.name}.ritter.family";
            aliases = ["pdf.ritter.family"];
            target = "http://localhost:8090";
            extraConfig = ''
              client_max_body_size 100M;
            '';
          }
        ];
      };
    };
}
