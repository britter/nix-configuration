{
  flake.modules.homeManager.ai-agents =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # The same checkout is a plugin for both harnesses: opencode loads the
      # .mjs, Claude Code the repo root as a personal plugin. Both resolve
      # hooks/ and skills/ relative to it, so the pinned source works as-is.
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

      calculationsContext = pkgs.writeText "calculations.md" ''
        # Calculations

        Never generate arithmetic results from memory — LLM arithmetic is
        unreliable. Compute every non-trivial calculation by calling a
        program: `bc -l` (`nix run nixpkgs#bc -l -- <<< "2+2"` when not on
        PATH), or a small Python script for anything involving units or
        formatting.

        File and disk sizes: mind the base. SI units (MB, GB, TB) are base
        10, binary units (MiB, GiB, TiB) are base 2. Tools disagree:
        `parted`, disk vendors, and marketing use base 10; `ls -h`, `du -h`,
        and `df -h` show base 2. Always state which base you computed with
        and match it to the tool you are feeding.

        When calculating, show the full chain: the expression handed to the
        calculator, its raw output, and the intermediate results leading to
        the final number. No unexplained jumps.
      '';
      calculationsPath = "${config.xdg.configHome}/agents/calculations.md";
      preferences = pkgs.writeText "preferences.md" ''
        # Working preferences

        - PR descriptions contain a Summary only. Don't add a "Test plan" section.
          Don't add references to implementation details that have been abanndonned
          later and never ended up in the PR.
        - Move files with `git mv`, never delete-and-recreate, so history is
          preserved.
        - Tee the output of long-running commands (e.g. build processes) into
          a file, e.g. `nix build ... 2>&1 | tee /tmp/opencode/build.log`. If
          an error happens later, inspect the file instead of re-running the
          command.
      '';
      preferencesPath = "${config.xdg.configHome}/agents/preferences.md";
    in
    {
      # Which harness is actually enabled is decided per user/host; this module
      # only carries the shared configuration for both.
      skills.programming.java.enable = true;
      skills.programming.nix.enable = true;
      skills.programming.rust.enable = true;
      skills.writing.avoid-ai-tropes.enable = true;

      programs.hunk = {
        enable = true;
        enableClaudeIntegration = config.programs.claude-code.enable;
        enableOpenCodeIntegration = config.programs.opencode.enable;
        settings.theme = "catppuccin-macchiato";
      };

      programs.nono = {
        enable = true;

        # `extends` nolabs-ai/opencode; everything else keeps nono's parser
        # defaults.
        profiles.opencode = {
          extends = [ "nolabs-ai/opencode" ];
          meta = {
            version = "1.0.0";
            description = "Runtime-discovered path additions for opencode";
          };
          filesystem = {
            allow = [
              "~/.config/gh"
              "~/.gradle"
            ];
            suppress_save_prompt = [
              "~/"
            ];
          };
        };
      };

      programs.opencode = {
        enableMcpIntegration = true;
        settings = {
          plugin = [ "${ponytail}/.opencode/plugins/ponytail.mjs" ];

          # opencode's native way to pull in external context.
          instructions = [
            hostPath
            scriptingPath
            toolsPath
            calculationsPath
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
            # fetch with the setup-grafana-mcp fish function below
            GRAFANA_SERVICE_ACCOUNT_TOKEN = "{env:GRAFANA_SERVICE_ACCOUNT_TOKEN}";
          };
        };
      };

      # Exports the token for servers.grafana above. A fish function (not a
      # script) so the export reaches the calling shell; start opencode from
      # that shell so the MCP server sees the token. Fish-specific because a
      # plain script can't mutate the parent environment. `rbw` is referenced
      # by store path so this works even without the bitwarden module; its
      # agent handles unlocking, no session env var involved.
      programs.fish.functions.setup-grafana-mcp = {
        description = "Export GRAFANA_SERVICE_ACCOUNT_TOKEN from Bitwarden";
        body = ''
          set -l item "Grafana MCP Service Account Token"
          set -l rbw ${lib.getExe pkgs.rbw}
          if set -q GRAFANA_SERVICE_ACCOUNT_TOKEN
            echo "GRAFANA_SERVICE_ACCOUNT_TOKEN already set"
            return 0
          end
          $rbw sync >/dev/null; or echo "rbw sync failed, using cached vault" >&2
          set -l token ($rbw get $item)
          if not set -q token[1]
            # never logged in on this machine — log in and retry once
            $rbw login
            and set token ($rbw get $item)
          end
          if not set -q token[1]
            echo "could not get '$item' from Bitwarden" >&2
            return 1
          end
          # -gx, not -x: plain -x inside a function scopes the var locally
          # and it vanishes when the function returns
          set -gx GRAFANA_SERVICE_ACCOUNT_TOKEN $token
          echo "GRAFANA_SERVICE_ACCOUNT_TOKEN exported from '$item'"
        '';
      };

      # Context files on disk, plus Claude Code's native references to them.
      xdg.configFile."agents/host.md".source = hostContext;
      xdg.configFile."agents/scripting.md".source = scriptingContext;
      xdg.configFile."agents/tools.md".source = toolsContext;
      xdg.configFile."agents/calculations.md".source = calculationsContext;
      xdg.configFile."agents/preferences.md".source = preferences;

      programs.claude-code = {
        enableMcpIntegration = true;
        plugins.ponytail = ponytail;

        # Claude Code rewrites settings.json at runtime, so anything toggled
        # from within a session (/config, /model) has to be declared here to
        # survive; the file is a read-only store symlink once home-manager
        # owns it.
        settings = {
          statusLine = {
            type = "command";
            command = "${ponytail}/hooks/ponytail-statusline.sh";
          };
          alwaysThinkingEnabled = true;
          effortLevel = "medium";
          enabledPlugins."gopls-lsp@claude-plugins-official" = true;
        };
        context = ''
          @${hostPath}
          @${scriptingPath}
          @${toolsPath}
          @${calculationsPath}
          @${preferencesPath}
        '';
      };
    };
}
