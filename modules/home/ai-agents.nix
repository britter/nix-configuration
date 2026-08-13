{
  flake.modules.homeManager.ai-agents =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Zero-dependency opencode plugin; resolves its hooks/ and skills/
      # relative to the .mjs, so we can run it straight from the pinned source.
      ponytail = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "v4.8.3";
        hash = "sha256-4ZT89GA5xnomNBIzY8Kh1yYP0AC9SeVhv406DEKpE3A=";
      };
      # Single source of truth on disk; each harness references it in its own
      # idiom (opencode's `instructions`, Claude's CLAUDE.md `@import`).
      scriptingContext = pkgs.writeText "scripting.md" ''
        # Scripting

        For anything beyond a trivial one-liner, write a Python script instead
        of a bash one-liner. Python is not installed on this host; run a script
        with `nix run nixpkgs#python3 -- script.py [args...]`. If the script
        needs a library, run it in a shell that provides it, e.g.
        `nix shell nixpkgs#python3 nixpkgs#python3Packages.requests -c python3 script.py`.
      '';
      hostContext = pkgs.writeText "host.md" ''
        # Host environment

        This host has Nix installed. Any CLI tool you need that is not already
        on `PATH` can be run ephemerally with `nix run nixpkgs#<tool> -- <args>`
        (or `nix shell nixpkgs#<tool> -c ...`) — never ask the user to install
        it or assume it is missing.

        The host is managed declaratively by a Nix flake, typically checked out
        at `~/github/britter/nix-configuration`
        (https://github.com/britter/nix-configuration). Persistent changes to
        the environment — installed packages, services, dotfiles — belong in
        that repo, not in imperative commands like `nix profile install` or
        hand-edited config files.
      '';
      # Important CLI tools installed on this host (see modules/home/programs/tools.nix).
      toolsContext = pkgs.writeText "tools.md" ''
        # CLI tools

        Prefer these installed tools over generic alternatives:

        - `gh` for GitHub access (issues, PRs, releases, gists)
        - `jq` for JSON parsing and formatting
        - `httpie` for making HTTP requests (`http --follow https://...`)
        - `yq` for YAML/JSON/TOML conversion
        - `fd` as a fast `find` replacement
        - `eza` as an `ls` replacement
        - `ripgrep` for recursive text search
        - `tokei` for counting lines of code
        - `sd` for simple find/replace on files (`sd -i 'old' 'new' src/**/*.rs`)
      '';
      hostPath = "${config.xdg.configHome}/agents/host.md";
      scriptingPath = "${config.xdg.configHome}/agents/scripting.md";
      toolsPath = "${config.xdg.configHome}/agents/tools.md";

      preferences = pkgs.writeText "preferences.md" ''
        # Working preferences

        - PR descriptions contain a Summary only. Don't add a "Test plan" section.
          Don't add references to implementation details that have been abanndonned
          later and never ended up in the PR.
        - Move files with `git mv`, never delete-and-recreate, so history is
          preserved.
      '';
      preferencesPath = "${config.xdg.configHome}/agents/preferences.md";

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
          # prefix+hjkl pane focus, prefix+r resize mode.
          keys = {
            prefix = "ctrl+b";
            detach = "prefix+d";
            split_vertical = "prefix+%";
            split_horizontal = "prefix+\"";
            copy_mode = "prefix+[";
            close_tab = "prefix+&";
            rename_tab = "prefix+,";
            last_pane = "prefix+;";

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
                };
          };
        };
      };

      # herdr's plugin registry is a derived cache of the parsed manifest, not
      # config, so it can't be generated declaratively. `plugin link` resolves
      # the path to the store, hence re-linking on every switch: that is what
      # keeps the registry pointing at the current build. A running herdr may
      # need a restart to pick up a freshly linked plugin.
      home.activation.herdrSplitsPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe pkgs.herdr} plugin link ${pkgs.herdr-splits-nvim} || true
      '';

      programs.hunk = {
        enable = true;
        enableGitIntegration = true;
        enableClaudeIntegration = true;
        enableOpenCodeIntegration = true;
        settings.theme = "catppuccin-macchiato";
      };

      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        settings = {
          plugin = [ "${ponytail}/.opencode/plugins/ponytail.mjs" ];

          # opencode's native way to pull in external context.
          instructions = [
            hostPath
            scriptingPath
            toolsPath
            preferencesPath
          ];

          # A primary agent (cycle to it with Tab) that asks before mutations,
          # like Claude Code's default. The built-in build agent is left as-is.
          agent.careful = {
            mode = "primary";
            permission = {
              edit = "ask";
              bash = "ask";
              webfetch = "ask";
              external_directory = "ask";
            };
          };
        };
      };
      programs.mcp = {
        enable = true;
        servers.grafana = {
          command = lib.getExe pkgs.mcp-grafana;
          env = {
            GRAFANA_URL = "https://testlens.grafana.net";
            # service account token has to be exported manually before use
            GRAFANA_SERVICE_ACCOUNT_TOKEN = "{env:GRAFANA_SERVICE_ACCOUNT_TOKEN}";
          };
        };
      };

      # Context files on disk, plus Claude Code's native references to them.
      xdg.configFile."agents/host.md".source = hostContext;
      xdg.configFile."agents/scripting.md".source = scriptingContext;
      xdg.configFile."agents/tools.md".source = toolsContext;
      xdg.configFile."agents/preferences.md".source = preferences;
      home.file.".claude/CLAUDE.md".text = ''
        @${hostPath}
        @${scriptingPath}
        @${toolsPath}
        @${preferencesPath}
      '';
    };
}
