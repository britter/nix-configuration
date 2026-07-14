{ config, ... }:
{
  flake.modules.homeManager.user-base = {
    imports = with config.flake.modules.homeManager; [
      config.flake.modules.generic.home-lab
      user-identity
      fish
      starship
      terminal-essentials
      tmux
      gpg
      git
      tools
      ssh
      java-config
      catppuccin
    ];
    programs.home-manager.enable = true;
  };
}
