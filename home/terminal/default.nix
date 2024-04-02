{pkgs, ...}: {
  imports = [
    ./bat.nix
    ./emacs.nix
    ./fish.nix
    ./tmux.nix
    ./tools.nix
  ];
}
