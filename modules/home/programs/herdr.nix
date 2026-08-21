{
  flake.modules.homeManager.herdr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Same palette source catppuccin/nix uses internally, so herdr's colors
      # track the flavor configured in modules/home/catppuccin.nix.
      palette =
        (lib.importJSON "${config.catppuccin.sources.palette}/palette.json")
        .${config.catppuccin.flavor}.colors;
    in
    {
      home.packages = [
        pkgs.nono
      ];

      programs.herdr = {
        enable = true;
        settings = {
          # config.toml is a read-only store symlink, so herdr cannot persist an
          # onboarding choice — opt out explicitly.
          onboarding = false;

          ui.sound.enabled = false;

          theme = {
            # herdr's built-in "catppuccin" is mocha; the token overrides below
            # turn it into the flavor configured repo-wide (macchiato).
            name = "catppuccin";
            custom = {
              panel_bg = palette.base.hex;
              surface_dim = palette.mantle.hex;
              surface0 = palette.surface0.hex;
              surface1 = palette.surface1.hex;
              overlay0 = palette.overlay0.hex;
              overlay1 = palette.overlay1.hex;
              subtext0 = palette.subtext0.hex;
              accent = palette.${config.catppuccin.accent}.hex;
              mauve = palette.mauve.hex;
              green = palette.green.hex;
              yellow = palette.yellow.hex;
              red = palette.red.hex;
              peach = palette.peach.hex;
            };
          };

          # tmux parity — only the bindings that differ from herdr's defaults.
          # Defaults already matching tmux: prefix+c new tab, prefix+n/p tab
          # cycling, prefix+1..9, prefix+x close pane, prefix+z zoom,
          # prefix+hjkl pane focus, prefix+r resize mode, prefix+w workspace
          # picker (tmux choose-window).
          keys = {
            prefix = "ctrl+b";
            detach = "prefix+d";
            split_vertical = "prefix+%";
            split_horizontal = "prefix+\"";
            copy_mode = "prefix+[";
            close_tab = "prefix+&";
            rename_tab = "prefix+,";
            last_pane = "prefix+;";

            # Workspaces mirror the tmux window bindings, shifted. prefix+shift+x
            # is free because close_tab moved to tmux's prefix+&.
            new_workspace = "prefix+shift+c";
            next_workspace = "prefix+shift+n";
            previous_workspace = "prefix+shift+p";
            switch_workspace = "prefix+shift+1..9";
            rename_workspace = "prefix+<";
            close_workspace = "prefix+shift+x";
            # prefix+shift+p is herdr's default rename_pane; workspace nav wins.
            rename_pane = "";

            # herdr has no tmux-style rotate-window; directional swap is the
            # closest equivalent. Shift of the prefix+hjkl focus bindings.
            swap_pane_left = "prefix+shift+h";
            swap_pane_down = "prefix+shift+j";
            swap_pane_up = "prefix+shift+k";
            swap_pane_right = "prefix+shift+l";

            # Seamless ctrl+hjkl between nvim splits and herdr panes, the way
            # vim-tmux-navigator does it under tmux. herdr has no conditional
            # binding, so the plugin's helper decides per keystroke whether to
            # forward the chord into nvim or move pane focus.
            command =
              lib.mapAttrsToList
                (key: direction: {
                  inherit key;
                  type = "plugin_action";
                  command = "herdr-splits.nav-${direction}";
                })
                {
                  "ctrl+h" = "left";
                  "ctrl+j" = "down";
                  "ctrl+k" = "up";
                  "ctrl+l" = "right";
                }
              ++ [
                # tmux break-pane. herdr has no keybinding for moving a pane out
                # of its tab, only the socket API, so shell out to the CLI with
                # the pane id herdr exports into the focused pane.
                {
                  key = "prefix+!";
                  type = "shell";
                  command = "${lib.getExe pkgs.herdr} pane move $HERDR_ACTIVE_PANE_ID --new-tab";
                  description = "Move pane to a new tab";
                }
                {
                  key = "prefix+alt+!";
                  type = "shell";
                  command = "${lib.getExe pkgs.herdr} pane move $HERDR_ACTIVE_PANE_ID --new-workspace";
                  description = "Move pane to a new workspace";
                }
              ];
          };
        };
      };

      # herdr's plugin registry is a derived cache of the parsed manifest, not
      # config, so it can't be generated declaratively. `plugin link` resolves
      # the path to the store, hence re-linking on every switch: that is what
      # keeps the registry pointing at the current build. A running herdr may
      # need a restart to pick up a freshly linked plugin.
      home.activation.herdrSplitsPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe pkgs.herdr} plugin link ${pkgs.vimPlugins.herdr-splits-nvim} || true
      '';
    };
}
