{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.home.terminal.tmux;
  yaml = pkgs.formats.yaml {};
  websiteConfig = {
    name = "website";
    root = "~/github/britter/website";
    windows = [
      {
        workspace = {
          layout = "main-horizontal";
          panes = [
            {editor = "v";}
            {dev-server = "npm run dev";}
            {term = "";}
          ];
        };
      }
    ];
  };
  gradlex-website = {
    name = "gradlex-website";
    root = "~/github/gradlex-org/gradlex-org.github.io";
    windows = [
      {
        workspace = {
          layout = "main-horizontal";
          panes = [
            {editor = "v";}
            {dev-server = "npm run dev";}
            {term = "";}
          ];
        };
      }
    ];
  };
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

            set -g @catppuccin_window_left_separator ""
            set -g @catppuccin_window_right_separator " "
            set -g @catppuccin_window_middle_separator " █"
            set -g @catppuccin_window_number_position "right"

            set -g @catppuccin_window_default_fill "number"
            set -g @catppuccin_window_default_text "#W"

            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#W"

            set -g @catppuccin_status_modules_right "directory session"
            set -g @catppuccin_status_left_separator  " "
            set -g @catppuccin_status_right_separator ""
            set -g @catppuccin_status_right_separator_inverse "no"
            set -g @catppuccin_status_fill "icon"
            set -g @catppuccin_status_connect_separator "no"

            set -g @catppuccin_directory_text "#{pane_current_path}"
          '';
        }
      ];
      extraConfig = ''
        # Open new pane splits in CWD
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
      '';
      tmuxinator.enable = true;
    };
    home.file.".config/tmuxinator/website.yml".source = yaml.generate "website.yaml" websiteConfig;
    home.file.".config/tmuxinator/gradlex-website.yml".source = yaml.generate "gradlex-website.yaml" gradlex-website;
  };
}
