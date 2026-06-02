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
    ./gaming
    ./git-server
    ./home-manager
    ./homepage
    ./https-proxy
    ./immich
    ./minio
    ./my-user
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
      gaming.enable = true;
      my-user.enable = true;
      sway.enable = true;
    };
  };
}
