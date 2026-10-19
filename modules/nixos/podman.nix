_: {
  flake.modules.nixos.podman = {
    virtualisation.podman = {
      enable = true;
      # dockerCompat = true;
    };
    environment.systemPackages = [
      # pkgs.podman-compose
    ];
  };
}
