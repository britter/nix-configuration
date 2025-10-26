{
  stdenv,
  gradle_9,
  makeWrapper,
  jre21_minimal,
}:
let
  gradle = gradle_9;
  jre = jre21_minimal;
  self = stdenv.mkDerivation (_finalAttrs: {
    pname = "lui";
    version = "0.0.1";

    src = ./.;

    nativeBuildInputs = [
      gradle
      makeWrapper
    ];

    mitmCache = gradle.fetchDeps {
      pkg = self;
      # update or regenerate this by running
      #  eval (nix build .#lui.mitmCache.updateScript --print-out-paths)
      data = ./deps.json;
    };

    # https://github.com/NixOS/nixpkgs/pull/455979
    gradleUpdateTask = "nixDownloadDeps --no-configuration-cache";

    installPhase = ''
      mkdir -p $out/bin
      tar -xf app/build/distributions/app.tar -C $out/

      makeWrapper $out/app/bin/app $out/bin/lui \
        --set JAVA_HOME ${jre}
    '';
  });
in
self
