_: {
  flake.modules.homeManager.ai-skills =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1 — plain
      # markdown, so we pin the raw revision and prepend skill frontmatter.
      avoidAiTropes = pkgs.linkFarm "avoid-ai-tropes-skill" {
        "SKILL.md" = pkgs.concatText "SKILL.md" [
          (pkgs.writeText "frontmatter.md" ''
            ---
            name: writing.avoid-ai-tropes
            description: Catalogue of AI writing tells — magic adverbs, "delve", em-dash overuse, "it's not X, it's Y", rule-of-three padding. Use when writing or editing prose a human will read: docs, READMEs, PR descriptions, commit messages, blog posts, emails.
            ---
          '')
          (pkgs.fetchurl {
            url = "https://gist.githubusercontent.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1/raw/bfe72673726cdd541b69463ed7129942f4bc19c8/tropes.md";
            hash = "sha256-BReDfbp6AkON/YSIVe2ULIxpuTyHplDyId94RplkXcg=";
          })
        ];
      };

      # Attribute name == skill directory name == name in the frontmatter, for
      # every harness that discovers skills by directory.
      skills = {
        "writing.avoid-ai-tropes" = {
          source = avoidAiTropes;
          cfg = config.skills.writing.avoid-ai-tropes;
        };
        "programming.tutor" = {
          source = ./skills/programming/tutor;
          cfg = config.skills.programming.tutor;
        };
        "programming.nix.expert" = {
          source = ./skills/programming/nix/expert;
          cfg = config.skills.programming.nix.expert;
        };
        "programming.rust.tutor" = {
          source = ./skills/programming/rust/tutor;
          cfg = config.skills.programming.rust.tutor;
        };
      };

      mkSkillOptions = name: {
        enable = lib.mkEnableOption "the ${name} skill";
        opencode.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.programs.opencode.enable;
          defaultText = lib.literalExpression "config.programs.opencode.enable";
          description = "Whether to install the ${name} skill for opencode.";
        };
        claude.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.programs.claude-code.enable;
          defaultText = lib.literalExpression "config.programs.claude-code.enable";
          description = "Whether to install the ${name} skill for Claude Code.";
        };
      };

      sourcesFor =
        harness:
        lib.mapAttrs (_: skill: skill.source) (
          lib.filterAttrs (_: skill: skill.cfg.enable && skill.cfg.${harness}.enable) skills
        );
    in
    {
      options.skills = {
        programming = {
          tutor = mkSkillOptions "programming.tutor";
          nix.expert = mkSkillOptions "programming.nix.expert";
          rust.tutor = mkSkillOptions "programming.rust.tutor";
        };
        writing.avoid-ai-tropes = mkSkillOptions "writing.avoid-ai-tropes";
      };

      # Both harness modules only act on these when they are enabled, so no
      # extra guard is needed here.
      config = {
        programs.opencode.skills = sourcesFor "opencode";
        programs.claude-code.skills = sourcesFor "claude";
      };
    };
}
