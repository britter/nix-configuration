{ config, ... }:
{
  flake.modules.homeManager.user-base = {
    imports = with config.flake.modules.homeManager; [
      config.flake.modules.generic.home-lab
      user-identity
      fish
      terminal-essentials
      tmux
      herdr
      gpg
      git
      hunk
      tools
      ssh
      java-config
      theme
    ];
    programs.home-manager.enable = true;
  };
}
