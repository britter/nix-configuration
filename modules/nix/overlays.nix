{ config, inputs, ... }:
{
  flake.overlays = {
    local-pkgs = final: _prev: import ../../packages { pkgs = final; };

    # Remove entries here once the referenced nixpkgs PR has been merged and
    # is in nixos-unstable.
    fixes = final: prev: {
      # Backport of https://github.com/NixOS/nixpkgs/pull/576874: fabric 3.2.3
      # is marked broken with invoke >= 3 (invoke was bumped to 3.0.3 in
      # nixpkgs without a fabric release supporting it). azure-cli (installed
      # by seeq-support) depends on fabric, so it breaks the evaluation of the
      # man page database. The fix updates fabric to an unreleased snapshot
      # that supports invoke v3 and drops the broken marker.
      #
      # Applied via pythonPackagesExtensions (not python3.override) because
      # azure-cli re-overrides the interpreter with its own packageOverrides,
      # which would drop a per-interpreter override.
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_pyfinal: pyprev: {
          fabric = pyprev.fabric.overrideAttrs (_old: {
            version = "3.2.3-unstable-2026-04-07";
            src = final.fetchFromGitHub {
              owner = "fabric";
              repo = "fabric";
              rev = "cc098ad475dbbe2e10aba72692d83aee58919570";
              hash = "sha256-Z1tGcjdLrzbqcbS6XwapSgDNpyLbBiO21yeqi7XhbpQ=";
            };
            meta = (_old.meta or { }) // {
              # https://github.com/fabric/fabric/issues/2376
              broken = false;
            };
          });
        })
      ];
    };

    default = inputs.nixpkgs.lib.composeManyExtensions [
      config.flake.overlays.local-pkgs
      config.flake.overlays.fixes
      inputs.nur.overlays.default
      inputs.llm-agents.overlays.shared-nixpkgs
    ];
  };
}
