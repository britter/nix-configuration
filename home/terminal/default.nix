{pkgs, ...}: {
  imports = [
    ./fish.nix
    ./tmux.nix
    ./tools.nix
  ];
}
