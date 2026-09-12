{ config, inputs, ... }:
{
  flake.overlays = {
    local-pkgs = final: _prev: import ../../packages { pkgs = final; };

    fixes = _final: _prev: {
    };

    default = inputs.nixpkgs.lib.composeManyExtensions [
      config.flake.overlays.local-pkgs
      config.flake.overlays.fixes
      inputs.nur.overlays.default
    ];
  };
}
