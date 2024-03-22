{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    git
    vim
    nix-tree
  ];
}
