{
  flake.modules.homeManager.ai-agent =
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
      hostPath = "${config.xdg.configHome}/agents/host.md";

      preferences = pkgs.writeText "preferences.md" ''
        # Working preferences

        - PR descriptions contain a Summary only. Don't add a "Test plan" section.
          Don't add references to implementation details that have been abanndonned
          later and never ended up in the PR.
        - Move files with `git mv`, never delete-and-recreate, so history is
          preserved.
      '';
      preferencesPath = "${config.xdg.configHome}/agents/preferences.md";
    in
    {
      home.packages = [ pkgs.nono ];

      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        settings = {
          plugin = [ "${ponytail}/.opencode/plugins/ponytail.mjs" ];

          # opencode's native way to pull in external context.
          instructions = [
            hostPath
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
      xdg.configFile."agents/preferences.md".source = preferences;
      home.file.".claude/CLAUDE.md".text = ''
        @${hostPath}
        @${preferencesPath}
      '';
    };
}
