{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.desktop.calibre;
in
{
  options.my.home.desktop.calibre = {
    enable = lib.mkEnableOption "calibre";
  };

  config =
    let
      sync-calibre-library = pkgs.writeShellScriptBin "sync-calibre-library" ''
        rsync -avz --no-o --no-g --delete "${config.home.homeDirectory}/Calibre Library/" srv-prod-2.ritter.family:/var/lib/calibre-library/
        ssh srv-prod-2.ritter.family "chown -R calibre-web:calibre-web /var/lib/calibre-library/ && systemctl restart calibre-web"
      '';
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        calibre
        sync-calibre-library
      ];
    };
}
