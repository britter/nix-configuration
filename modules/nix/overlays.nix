{ config, inputs, ... }:
{
  flake.overlays = {
    local-pkgs = final: _prev: import ../../packages { pkgs = final; };

    fixes = _final: prev: {
      # backport of https://github.com/NixOS/nixpkgs/pull/557809
      stirling-pdf = prev.stirling-pdf.overrideAttrs (prev: {
        patches = prev.patches ++ [
          ./skip-tests-with-expired-certs.patch
        ];
      });
    };

    default = inputs.nixpkgs.lib.composeManyExtensions [
      config.flake.overlays.local-pkgs
      config.flake.overlays.fixes
      inputs.nur.overlays.default
    ];
  };
}
