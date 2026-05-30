_: {
  flake.modules.nixos.system-base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        curl
        dig
        git
        lsof
        neovim
        nix-tree
        nix-output-monitor
        nh
        unzip
        tmux
        wget
        zip
      ];
    };
}
