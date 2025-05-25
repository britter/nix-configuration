{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.home.terminal.tmux;
in
{
  imports = [ ./tmuxinator.nix ];
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
      shell = lib.getExe pkgs.fish;
      # Prevent tmux from receiving ESC presses
      # without this switching modes in vim has a noticable input lag
      escapeTime = 0;
      mouse = true;
      keyMode = "vi";
      terminal = "tmux-256color";
      plugins = [
        pkgs.tmuxPlugins.vim-tmux-navigator
        {
          plugin = pkgs.tmuxPlugins.catppuccin;
          extraConfig = ''
            set-option -g status-position top

            set -g @catppuccin_window_status_style "rounded"

            set -g status-right-length 100
            set -g status-left-length 100
            set -g status-left ""
            set -g status-right "#{E:@catppuccin_status_application}"
            set -ag status-right "#{E:@catppuccin_status_session}"
            set -ag status-right "#{E:@catppuccin_status_uptime}"
          '';
        }
      ];
      extraConfig = ''
        # Open new pane splits in CWD
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
      '';
      tmuxinator = {
        enable = true;
        projects = {
          website = {
            root = "~/github/britter/website";
            windows = [
              {
                workspace = {
                  layout = "main-horizontal";
                  panes = [
                    { editor = "v"; }
                    { dev-server = "npm run dev"; }
                    { term = ""; }
                  ];
                };
              }
            ];
          };
          gradlex-website = {
            root = "~/github/gradlex-org/gradlex-org.github.io";
            windows = [
              {
                workspace = {
                  layout = "main-horizontal";
                  panes = [
                    { editor = "v"; }
                    { dev-server = "npm run dev"; }
                    { term = ""; }
                  ];
                };
              }
            ];
          };
        };
      };
    };
  };
}
