{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    git
    helix
    nix-tree
  ];

  programs.fish.enable = true;
}
