{ config, ... }:
{
  flake.modules.nixos.srv-prod-5 = {
    imports = with config.flake.modules.nixos; [
      system-server
      proxmox-vm
      tailscale
      navidrome-on-srv-prod-5
      romm-on-srv-prod-5
      (config.flake.factory.sops { secretsFile = ./secrets.yaml; })
    ];

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?
  };
}
