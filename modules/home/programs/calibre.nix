_: {
  flake.modules.homeManager.calibre =
    { config, pkgs, ... }:
    let
      sync-calibre-library = pkgs.writeShellScriptBin "sync-calibre-library" ''
        rsync -avz --no-o --no-g --delete "${config.home.homeDirectory}/Calibre Library/" srv-prod-2.ritter.family:/var/lib/calibre-library/
        ssh srv-prod-2.ritter.family "chown -R calibre-web:calibre-web /var/lib/calibre-library/ && systemctl restart calibre-web"
      '';
    in
    {
      home.packages = with pkgs; [
        calibre
        sync-calibre-library
      ];
    };
}
