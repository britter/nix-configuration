{ config, ... }:
{
  flake.modules.nixos.srv-prod-4 = {
    imports = with config.flake.modules.nixos; [
      immich
    ];

    boot.supportedFilesystems = [ "nfs" ];
    fileSystems."/srv/immich-media" = {
      fsType = "nfs";
      device = "storage.ritter.family:/mnt/default-pool/immich-media";
    };
    systemd.services.immich-server = {
      unitConfig = {
        RequiresMountsFor = "/srv/immich-media";
      };
    };
    services.immich.mediaLocation = "/srv/immich-media";
  };
}
