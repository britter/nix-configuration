_: {
  flake.modules.homeManager.tmux =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
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
        historyLimit = 10000;
        plugins = [
          pkgs.tmuxPlugins.vim-tmux-navigator
          pkgs.tmuxPlugins.yank
        ];

        # mkAfter because stylix's tmux target writes its colors into
        # extraConfig as well, and the last definition of an option wins.
        extraConfig =
          let
            inherit (config.lib.stylix.colors.withHashtag)
              base00
              base03
              base05
              base0A
              base0D
              ;
          in
          lib.mkAfter ''
            # fix colors
            set-option -sa terminal-overrides ",xterm*:Tc"

            # Configure vim like selection in copy mode
            bind-key -T copy-mode-vi v send-keys -X begin-selection
            bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
            bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

            # Open new pane splits in CWD
            bind '"' split-window -v -c "#{pane_current_path}"
            bind % split-window -h -c "#{pane_current_path}"

            # Highlight active pane
            set-option -g pane-active-border-style "fg=${base0D}"
            set-option -g pane-border-indicators arrows

            # Status line. The stylix target only sets the base styles, so the
            # layout is spelled out here: windows on the left, the running
            # command, session name and clock on the right, no separators.
            set-option -g status-position top
            set-option -g status-justify left
            set-option -g status-style "fg=${base05},bg=${base00}"

            set-option -g status-left ""
            set-option -g status-right-length 60
            set-option -g status-right "#[fg=${base03}]#{pane_current_command} #[fg=${base0D}]#S #[fg=${base03}]%H:%M "

            set-window-option -g window-status-separator ""
            set-window-option -g window-status-format "#[fg=${base03}] #I #W "
            set-window-option -g window-status-current-format "#[fg=${base0A},bold] #I #W#{?window_zoomed_flag, Z,} "
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
