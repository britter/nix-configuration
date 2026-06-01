{ config, ... }:
{
  flake.modules.nixos.system-base =
    { pkgs, ... }:
    {
      imports = [ config.flake.modules.nixos.i18n ];

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
