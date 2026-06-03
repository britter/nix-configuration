{ config, ... }:
{
  flake.modules.nixos.srv-prod-5 = {
    imports = with config.flake.modules.nixos; [
      ../../../_needs_migration/modules
      system-server
      proxmox-vm
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    my.modules = {
      navidrome.enable = true;
      tailscale.enable = true;
    };

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

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?
  };
}
