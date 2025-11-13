{
  stdenv,
  fetchFromGitHub,
  gradle_9,
  jre,
  makeWrapper,
}:
let
  gradle = gradle_9;
  self = stdenv.mkDerivation (_finalAttrs: {
    # see https://github.com/NixOS/nixpkgs/blob/b32a0943687d2a5094a6d92f25a4b6e16a76b5b7/doc/languages-frameworks/gradle.section.md
    pname = "groovy-language-server";
    version = "unstable-2025-10-09";

    src = fetchFromGitHub {
      owner = "GroovyLanguageServer";
      repo = "groovy-language-server";
      rev = "0466842f2b9e7d2c4620e81e3acf85e56c71097f";
      sha256 = "sha256-2KRMrJGcx52uBQGyZ8cRW5y9ZUwxMoe1eF90oN3Yppw=";
    };

    nativeBuildInputs = [
      gradle
      makeWrapper
    ];

    mitmCache = gradle.fetchDeps {
      pkg = self;
      # update or regenerate this by running
      #  eval (nix build .#groovy-language-server.mitmCache.updateScript --print-out-paths)
      data = ./deps.json;
    };

    # defaults to "assemble"
    gradleBuildTask = "shadowJar";

    # will run the gradleCheckTask (defaults to "test")
    doCheck = true;

    installPhase = ''
      mkdir -p $out/{bin,share/groovy-language-server}
      cp build/libs/source-all.jar $out/share/groovy-language-server/groovy-language-server-all.jar

      makeWrapper ${jre}/bin/java $out/bin/groovy-language-server \
        --add-flags "-jar $out/share/groovy-language-server/groovy-language-server-all.jar"
    '';
  });
in
self
