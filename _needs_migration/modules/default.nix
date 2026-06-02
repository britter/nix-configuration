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
    ./fonts
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
    ./proxmox-vm
    ./restic-restore
    ./sound
    ./stirling-pdf
    ./sway
    ./system-recovery
    ./tailscale
    ./vaultwarden
  ];

  config = {
    my.modules = lib.optionalAttrs (cfg.role == "desktop") {
      fonts.enable = true;
      gaming.enable = true;
      my-user.enable = true;
      sound.enable = true;
      sway.enable = true;
      system-recovery.enable = true;
    };
  };
}
