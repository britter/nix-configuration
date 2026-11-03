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

    # Remove entries here once the referenced nixpkgs PR has been merged and
    # is in nixos-unstable.
    fixes = final: prev: {
      # Backport of https://github.com/NixOS/nixpkgs/pull/582594: fabric is
      # marked broken with invoke >= 3 (invoke was bumped to 3.0.3 in
      # nixpkgs), which breaks azure-cli (installed by seeq-support) and thus
      # the evaluation of the man page database. Upstream only fixed the
      # invoke 3 incompatibility on main (the unreleased 4.x line) while
      # pinning 3.x to invoke < 3, so apply the upstream commit 7fa309db as a
      # patch to 3.2.3 and relax the invoke constraint instead of building an
      # unreleased snapshot.
      #
      # Applied via pythonPackagesExtensions (not python3.override) because
      # azure-cli re-overrides the interpreter with its own packageOverrides,
      # which would drop a per-interpreter override.
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_pyfinal: pyprev: {
          fabric = pyprev.fabric.overrideAttrs (_old: {
            patches = (_old.patches or [ ]) ++ [
              # Upstream fix for invoke >= 3, only on main (4.x) so far.
              # https://github.com/fabric/fabric/issues/2376
              (final.fetchpatch {
                url = "https://github.com/fabric/fabric/commit/7fa309db9dd5dac69079c1fb83b6f579555f7d53.patch";
                hash = "sha256-HxdV1XbsytBYOHV8WqcpKMpqGRkbXD/UlmAFSrmsFTg=";
              })
            ];
            pythonRelaxDeps = [ "invoke" ];
            meta = (_old.meta or { }) // {
              # https://github.com/fabric/fabric/issues/2376
              broken = false;
            };
          });
        })
      ];

      # calibre's test suite fails with `ModuleNotFoundError: No module named
      # 'speechd'`: the speechd package in nixos-unstable never builds its
      # Python bindings, because its configure script cannot find a Python
      # interpreter (it is only in buildInputs, and speechd sets strictDeps).
      # Nothing that depends on speechd can be fixed without rebuilding the
      # world, so disable speech support instead. This drops the
      # speech-dispatcher TTS integration (and piper-tts) from calibre until
      # the packaging bug is fixed upstream.
      calibre = prev.calibre.override {
        speechSupport = false;
      };
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
