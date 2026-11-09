{ config, inputs, ... }:
{
  flake.overlays = {
    local-pkgs =
      final: _prev:
      import ../../packages { pkgs = final; }
      // {
        # pkgs.writers-style helper: builds an Agent Skill directory and
        # validates it against the Agent Skills spec in the same build. A
        # function, hence not a member of the packages registry
        # (`perSystem.packages` only accepts derivations).
        writeSkill = final.callPackage ../../packages/write-skill { };
      };

    fixes = _final: _prev: {
    };

    default = inputs.nixpkgs.lib.composeManyExtensions [
      config.flake.overlays.local-pkgs
      config.flake.overlays.fixes
      inputs.nur.overlays.default
      inputs.llm-agents.overlays.shared-nixpkgs
      inputs.nixpkgs-pr.overlays.default
    ];
  };
}
