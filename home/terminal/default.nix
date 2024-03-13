{pkgs, ...}: {
  imports = [
    ./emacs.nix
    ./fish.nix
    ./tmux.nix
    ./tools.nix
  ];
}
