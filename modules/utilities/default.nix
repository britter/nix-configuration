{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    curl
    dig
    git
    lsof
    neovim
    nix-tree
    unzip
    tmux
    wget
    zip
  ];
}
