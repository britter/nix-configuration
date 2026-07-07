_: {
  flake.modules.nixos.podman =
    { pkgs, ... }:
    {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
      };
      environment.systemPackages = [
        pkgs.podman-compose
      ];
    };
}
