{pkgs, ...}: {
  imports = [
    ./alacritty.nix
    ./fish.nix
    ./tmux.nix
    ./tools.nix
  ];
}
