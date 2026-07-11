{ config, ... }: {

  flake.modules.homeManager.terminal-essentials =
    { pkgs, ... }:
    {
      imports = with config.flake.modules.homeManager; [
        direnv
      ];

      programs.bat = {
        enable = true;
        config.map-syntax = [ "*.tofu:Terraform" ];
      };

      programs.btop.enable = true;
      # required for catppuccin theming of btop
      xdg.enable = true;

      programs.fzf = {
        enable = true;
        defaultCommand = "${pkgs.ripgrep}/bin/rg --files --hidden --glob '!.git'";
      };

      programs.gh = {
        enable = true;
        extensions = with pkgs; [ gh-get ];
        settings.git_protocol = "ssh";
      };

      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        # default for stateVersion >= 26.05
        shellWrapperName = "y";
      };
    };
}
