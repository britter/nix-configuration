{
  flake.allowUnfreePackages = [ "claude-code" ];
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

        The host is managed declaratively by a Nix flake, checked out at
        `~/github/britter/nix-configuration`
        (https://github.com/britter/nix-configuration). Persistent changes to
        the environment — installed packages, services, dotfiles — belong in
        that repo, not in imperative commands like `nix profile install` or
        hand-edited config files.

        The config repo is your source of truth: you can look anything up
        there — installed packages, enabled services, skills, nono sandbox
        profiles, dotfiles. When in doubt about how this host is configured,
        read the relevant module in that directory instead of guessing or
        asking the user.

        Skills you have available (e.g. the `skills.programming.*` and
        `skills.writing.*` entries) are installed from that repo; if asked to
        create, edit, or remove a skill, make the change in the config
        project, not in the generated files under `~/.config`.

        The same applies to nono sandbox profiles: they are declared in the
        config project (`modules/home/ai/ai-agents.nix`,
        `modules/home/nono-base.nix`) and rendered to
        `~/.config/nono/profiles/`. To modify sandbox permissions, edit the
        profile definitions in the config project — never hand-edit or
        promote drafts in `~/.config/nono` directly.
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
        - Tee the output of long-running commands (e.g. build processes) into
          a file, e.g. `nix build ... 2>&1 | tee /tmp/opencode/build.log`. If
          an error happens later, inspect the file instead of re-running the
          command.
      '';
      preferencesPath = "${config.xdg.configHome}/agents/preferences.md";
      plansContext = pkgs.writeText "plans.md" ''
        # Local plan documents

        When working on a task that benefits from written planning — approach
        sketches, TODO lists, research notes, step-by-step plans — store those
        documents in a top-level `.my-plans/` directory of the repository you
        are working in. The directory is globally git-ignored, so nothing in
        it will ever be committed.

        Conventions:

        - Create one subdirectory per task: `.my-plans/<task-slug>/`.
        - If you know an issue number for the task, include it in the
          directory name, e.g. `.my-plans/42-fix-inotify-leak/`. Prefer
          `<issue-number>-<short-slug>`; without an issue number use just a
          short descriptive slug.
        - Inside the task directory you are free to organize files as you
          see fit (plan.md, notes.md, scratch scripts, checklists).
        - Reference the plan documents in your replies when they contain the
          current state of the work, and keep them up to date as the task
          evolves.
      '';
      plansPath = "${config.xdg.configHome}/agents/plans.md";
    in
    {
      # Which harness is actually enabled is decided per user/host; this module
      # only carries the shared configuration for both.
      skills.programming.java.enable = true;
      skills.programming.nix.enable = true;
      skills.programming.rust.enable = true;
      skills.writing.enable = true;
      skills.math.enable = true;

      # Scratch directory for agent plan documents (see plansPath below).
      # programs.git.ignores feeds git's global core.excludesFile, so
      # `.my-plans/` is ignored in every repository without each repo
      # carrying its own .gitignore entry.
      programs.git.ignores = [ ".my-plans/" ];

      programs.hunk = {
        enable = true;
        enableClaudeIntegration = config.programs.claude-code.enable;
        enableOpenCodeIntegration = config.programs.opencode.enable;
        settings.theme = "catppuccin-macchiato";
      };

      programs.nono = {
        enable = true;

        profiles =
          let
            baseProfile = {
              filesystem = {
                read = [
                  "~/github/britter/nix-configuration"
                  "~/.config/gh"
                  "~/.docker"
                  # Socket directory of live hunk review sessions; without it
                  # the hunk-review skill cannot reach the MCP server.
                  "/run/user/${toString config.home.uid}/hunk-mcp"
                ];
                allow = [
                  "~/.m2"
                  "~/.gradle"
                  # Rootless container runtime state. Write access is required
                  # so agents can actually RUN containers, not just inspect
                  # them: crun/ holds runtime state, netns/ receives named
                  # network namespace bind mounts, containers/ and libpod/ and
                  # podman/ carry podman's state and API sockets.
                  "/run/user/${toString config.home.uid}/containers"
                  "/run/user/${toString config.home.uid}/crun"
                  "/run/user/${toString config.home.uid}/libpod"
                  "/run/user/${toString config.home.uid}/netns"
                  "/run/user/${toString config.home.uid}/podman"
                ];
                suppress_save_prompt = [
                  "~/"
                ];
              };
            };
          in
          {
            opencode = {
              extends = [ "nolabs-ai/opencode" ];
              meta = {
                version = "1.0.0";
                description = "Runtime-discovered path additions for opencode";
              };
            }
            // baseProfile;
            claude = {
              extends = [ "nolabs-ai/claude" ];
              meta = {
                version = "1.0.0";
                description = "Runtime-discovered path additions for claude";
              };
              # The pack grants read-write only on /tmp/claude-$UID; the rest of /tmp is
              # write-only.
              environment.set_vars = {
                # Claude Code appends claude-<uid> to this; keeps its own files in /tmp/claude-$UID
                # even though TMPDIR below points there.
                CLAUDE_CODE_TMPDIR = "/tmp";
                # Tools started from Claude (tempfile, pytest, Gradle, ...) need a temp dir they can
                # read back; the rest of /tmp is write-only in the sandbox.
                TMPDIR = "/tmp/claude-${toString config.home.uid}";
              };
            }
            // baseProfile;

            # Sandboxed profile for AI work in the finances repo: the agent
            # may migrate LaTeX→Typst and build invoicing tooling, but must
            # never see the production journals, the git history, or existing
            # invoices/quotations. Uses $WORKDIR so the grant follows
            # wherever the checkout lives (launch from the repo root).
            #
            # Linux/Landlock is strictly allow-list: a deny overlapping an
            # allow/read/write grant is a hard startup error, so the sensitive
            # paths (main.journal, journals/, .git/, invoices/2*, quotations/2*)
            # are simply never granted. Do not add a `deny` list as a backstop
            # here — on this Linux-only host it enforces nothing and only
            # emits "Glob deny" warnings at startup.
            finances = {
              extends = [ "opencode" ];
              meta = {
                version = "1.2.0";
                description = "Finances repo access without journals, git history, or production invoices/quotations";
              };
              # The opencode pack grants the launch directory read-write
              # (workdir.access: "readwrite"), which at startup would pull the
              # whole finances repo — main.journal, .git/, journals/,
              # invoices/2*, quotations/2* — into scope, defeating the
              # allow-list below. Set it to "none": no CWD prompt at startup
              # and no grant; the agent may only touch what is granted
              # explicitly in the filesystem section. ("none" is the schema
              # default; this override just neutralizes the inherited pack
              # value.)
              workdir.access = "none";
              filesystem = {
                # Everything else the agent may read AND write: helper
                # scripts, both template trees, and a scratch directory for
                # draft invoices/quotations it generates (create it with
                # `mkdir -p invoices/drafts quotations/drafts` before the
                # session; missing paths would expand to nothing).
                allow = [
                  "$WORKDIR/scripts"
                  "$WORKDIR/invoices/templates"
                  "$WORKDIR/invoices/drafts"
                  "$WORKDIR/quotations/templates"
                  "$WORKDIR/quotations/drafts"
                  "$WORKDIR/flake.nix"
                  "$WORKDIR/flake.lock"
                  "$WORKDIR/README.md"
                  "$WORKDIR/AGENTS.md"
                  "$WORKDIR/Taskfile.yml"
                ];
              };
            };
          };
      };

      # Pre-create Claude's temp dir so nono's Landlock grant for it applies
      # (nolabs-ai/nono-packs#44).
      systemd.user.tmpfiles.rules = [
        "d /tmp/claude-${toString config.home.uid} 0700 - - -"
      ];

      # Disable opencode's file watcher: on NixOS it exhausts the system-wide
      # inotify watch budget (https://github.com/anomalyco/opencode/issues/55367).
      programs.opencode = {
        package = pkgs.symlinkJoin {
          name = "opencode2";
          paths = [ pkgs.llm-agents.opencode2 ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/opencode2 \
              --set OPENCODE_DISABLE_FILEWATCHER true
          '';
        };
        enableMcpIntegration = true;
        settings = {
          plugin = [ "${ponytail}/.opencode/plugins/ponytail.mjs" ];

          # opencode's native way to pull in external context.
          instructions = [
            hostPath
            scriptingPath
            toolsPath
            preferencesPath
            plansPath
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
      xdg.configFile."agents/preferences.md".source = preferences;
      xdg.configFile."agents/plans.md".source = plansContext;

      programs.claude-code = {
        enable = true;
        package = pkgs.llm-agents.claude-code;
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
          theme = "dark";
          enabledPlugins = {
            "nono@nolabs-ai" = true;
          };
        };
        context = ''
          @${hostPath}
          @${scriptingPath}
          @${toolsPath}
          @${preferencesPath}
          @${plansPath}
        '';
      };
    };
}
