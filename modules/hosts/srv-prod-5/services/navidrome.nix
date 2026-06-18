{ config, ... }:
{
  flake.modules.nixos.navidrome-on-srv-prod-5 = {
    imports = with config.flake.modules.nixos; [
      navidrome
    ];

    fileSystems."/srv/navidrome-library" = {
      fsType = "nfs";
      device = "storage.ritter.family:/mnt/default-pool/navidrome-library";
    };
    systemd.services.navidrome = {
      unitConfig = {
        RequiresMountsFor = "/srv/navidrome-library";
      };
    };
    services.navidrome.settings.MusicFolder = "/srv/navidrome-library";
  };
}
