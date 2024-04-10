{pkgs, ...}: {
  imports = [
    ./bat.nix
    ./btop.nix
    ./fish.nix
    ./tmux.nix
    ./tools.nix
  ];
}
