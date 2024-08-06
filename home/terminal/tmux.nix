{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.tmux;
in {
  options.my.home.terminal.tmux = {
    enable = lib.mkEnableOption "tmux";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      baseIndex = 1;
      clock24 = true;
      disableConfirmationPrompt = true;
      sensibleOnTop = true;
      shell = "${pkgs.fish}/bin/fish";
      plugins = with pkgs; [
        tmuxPlugins.vim-tmux-navigator
      ];
      extraConfig = ''
        # Open new pane splits in CWD
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        # Prevent tmux from receiving ESC presses
        # without this switching modes in helix or vim has a noticable input lag
        set -sg escape-time 0
      '';
    };
  };
}
