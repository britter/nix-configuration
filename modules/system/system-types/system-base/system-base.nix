{ config, ... }:
{
  flake.modules.nixos.system-base =
    { pkgs, ... }:
    {
      imports = [
        config.flake.modules.generic.systemConstants
        config.flake.modules.generic.home-lab
      ];

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
