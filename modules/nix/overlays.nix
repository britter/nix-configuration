{ config, inputs, ... }:
{
  flake.overlays = {
    local-pkgs = final: _prev: import ../../packages { pkgs = final; };

    fixes = final: prev: {
      calibre-web = prev.calibre-web.overrideAttrs (prev: {
        pythonRelaxDeps = prev.pythonRelaxDeps ++ [ "requests" ];
      });
      gh = prev.gh.overrideAttrs (prev: {
        nativeBuildInputs = prev.nativeBuildInputs ++ [ final.makeWrapper ];
        installPhase = prev.installPhase + ''
          wrapProgram $out/bin/gh \
            --set GH_TELEMETRY false
        '';
      });
    };

    default = inputs.nixpkgs.lib.composeManyExtensions [
      config.flake.overlays.local-pkgs
      config.flake.overlays.fixes
      inputs.nur.overlays.default
    ];
  };
}
