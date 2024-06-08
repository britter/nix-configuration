{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    dig
    git
    helix
    nix-tree
  ];

  programs.fish.enable = true;
}
