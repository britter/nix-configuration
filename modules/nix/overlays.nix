{ config, inputs, ... }:
{
  flake.overlays = {
    local-pkgs = final: _prev: import ../../packages { pkgs = final; };

    fixes = final: prev: {
      # Workaround for https://github.com/NixOS/nixpkgs/pull/540681: pip-chill
      # 1.0.3 (a transitive dep) fails to build on Python 3.14 because it imports
      # the removed pkg_resources. Bump it to 1.0.5, which uses importlib.metadata,
      # and relax the certifi/chardet upper bounds calibre-web can't satisfy.
      calibre-web =
        (prev.calibre-web.override {
          python3Packages = prev.python3Packages.overrideScope (
            _pyfinal: pyprev: {
              pip-chill = pyprev.pip-chill.overridePythonAttrs (_old: rec {
                version = "1.0.5";
                src = final.fetchPypi {
                  pname = "pip_chill";
                  inherit version;
                  hash = "sha256-55vFFKv+FE8u9SKQ9ZZ30nnLBbQIT6n4FLvlzA6gTBw=";
                };
                dependencies = [ ];
              });
            }
          );
        }).overrideAttrs
          (prev: {
            pythonRelaxDeps = prev.pythonRelaxDeps ++ [
              "requests"
              "certifi"
              "chardet"
            ];
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
