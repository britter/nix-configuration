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
            name: avoid-ai-tropes
            description: Catalogue of AI writing tells — magic adverbs, "delve", em-dash overuse, "it's not X, it's Y", rule-of-three padding. Use when writing or editing prose a human will read: docs, READMEs, PR descriptions, commit messages, blog posts, emails.
            ---
          '')
          (pkgs.fetchurl {
            url = "https://gist.githubusercontent.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1/raw/bfe72673726cdd541b69463ed7129942f4bc19c8/tropes.md";
            hash = "sha256-BReDfbp6AkON/YSIVe2ULIxpuTyHplDyId94RplkXcg=";
          })
        ];
      };

      # https://github.com/danyuchn/asd-ste100-skill — upstream's skill name is
      # already `asd-ste100`, matching ours.
      asdSte100 = pkgs.fetchFromGitHub {
        owner = "danyuchn";
        repo = "asd-ste100-skill";
        rev = "8da6b6340aa22faf46fd07db8efbdea010cd38d9";
        hash = "sha256-s1SVG0ecMcrej45kyQ1s78lGTzscv3CV3M5UGsZwckE=";
      };

      # Skill names are flat and hyphenated per the Agent Skills spec (the
      # frontmatter `name` allows lowercase alphanumerics and hyphens only, and
      # must match the skill's directory name); the harnesses install each
      # source as `skills/<name>/`. Categories live in the directory layout
      # below and in `groups`, not in the names.
      sources = {
        "tutor" = ./skills/programming/tutor;
        "java-expert" = ./skills/programming/java/java-expert;
        "java-gradle" = ./skills/programming/java/java-gradle;
        "java-maven" = ./skills/programming/java/java-maven;
        "nix-expert" = ./skills/programming/nix/nix-expert;
        "nix-tutor" = ./skills/programming/nix/nix-tutor;
        "rust-tutor" = ./skills/programming/rust/rust-tutor;
        "avoid-ai-tropes" = avoidAiTropes;
        "asd-ste100" = asdSte100;
        "calculations" = ./skills/math/calculations;
      };

      # One enable flag per group, because the skills within a group reference
      # each other: a language's expert skill delegates to its build tool
      # skills, and a language tutor is written as an addition to the general
      # one. A group therefore also lists the skills it builds on. Group names
      # become the option path under `skills`.
      groups = {
        "programming.java" = [
          "java-expert"
          "java-gradle"
          "java-maven"
        ];
        "programming.nix" = [
          "tutor"
          "nix-expert"
          "nix-tutor"
        ];
        "programming.rust" = [
          "tutor"
          "rust-tutor"
        ];
        "writing" = [
          "avoid-ai-tropes"
          "asd-ste100"
        ];
        "math" = [ "calculations" ];
      };

      mkGroupOptions = name: {
        enable = lib.mkEnableOption "the ${name} skills";
        opencode.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.programs.opencode.enable;
          defaultText = lib.literalExpression "config.programs.opencode.enable";
          description = "Whether to install the ${name} skills for opencode.";
        };
        claude.enable = lib.mkOption {
          type = lib.types.bool;
          default = config.programs.claude-code.enable;
          defaultText = lib.literalExpression "config.programs.claude-code.enable";
          description = "Whether to install the ${name} skills for Claude Code.";
        };
      };

      cfgFor = name: lib.getAttrFromPath (lib.splitString "." name) config.skills;

      sourcesFor =
        harness:
        lib.getAttrs (lib.concatLists (
          lib.mapAttrsToList (
            name: members: if (cfgFor name).enable && (cfgFor name).${harness}.enable then members else [ ]
          ) groups
        )) sources;
    in
    {
      options.skills = lib.foldl' lib.recursiveUpdate { } (
        lib.mapAttrsToList (
          name: _: lib.setAttrByPath (lib.splitString "." name) (mkGroupOptions name)
        ) groups
      );

      # Both harness modules only act on these when they are enabled, so no
      # extra guard is needed here.
      config = {
        programs.opencode.skills = sourcesFor "opencode";
        programs.claude-code.skills = sourcesFor "claude";
      };
    };
}
