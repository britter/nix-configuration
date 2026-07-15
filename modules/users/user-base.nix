{ config, ... }:
{
  flake.modules.homeManager.user-base = {
    imports = with config.flake.modules.homeManager; [
      config.flake.modules.generic.home-lab
      config.flake.modules.generic.systemConstants
      user-identity
      fish
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
