{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    dig
    git
    helix
    lsof
    nix-tree
    tmux
  ];

  programs.fish.enable = true;
}
