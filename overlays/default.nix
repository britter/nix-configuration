{
  my-pkgs,
  nur,
}:
final: prev:
my-pkgs
// (nur.overlays.default final prev)
// {
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
}
