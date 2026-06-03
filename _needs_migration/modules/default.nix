{
  config,
  lib,
  ...
}:
let
  cfg = config.my.host;
in
{
  imports = [
    ./acme
    ./adguard
    ./calibre-web
    ./dirty-frag-fix
    ./git-server
    ./homepage
    ./https-proxy
    ./immich
    ./minio
    ./navidrome
    ./nextcloud
    ./nix
    ./options
    ./restic-restore
    ./stirling-pdf
    ./sway
    ./tailscale
    ./vaultwarden
  ];

  config = {
    my.modules = lib.optionalAttrs (cfg.role == "desktop") {
      sway.enable = true;
    };
  };
}
