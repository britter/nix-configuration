{pkgs, ...}: {
  imports = [
    ./bat.nix
    ./fish.nix
    ./tmux.nix
    ./tools.nix
  ];
}
