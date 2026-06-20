{ config, ... }:
{
  flake.modules.homeManager.user-base = {
    imports = with config.flake.modules.homeManager; [
      config.flake.modules.generic.home-lab
      user-identity
      fish
      terminal-essentials
      tmux
      gpg
      git
      tools
      java-config
      catppuccin
    ];
  };
}
