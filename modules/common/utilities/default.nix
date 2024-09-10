{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    dig
    git
    helix
    nix-tree
    tmux
  ];

  programs.fish.enable = true;
}
