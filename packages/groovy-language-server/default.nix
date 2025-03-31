{
  stdenv,
  fetchFromGitHub,
  gradle_7,
  jre,
  makeWrapper,
}:
let
  self = stdenv.mkDerivation (_finalAttrs: {
    # see https://github.com/NixOS/nixpkgs/blob/b32a0943687d2a5094a6d92f25a4b6e16a76b5b7/doc/languages-frameworks/gradle.section.md
    pname = "groovy-language-server";
    version = "unstable-2024-02-01";

    src = fetchFromGitHub {
      owner = "GroovyLanguageServer";
      repo = "groovy-language-server";
      rev = "4866a3f2c180f628405b1e4efbde0949a1418c10";
      sha256 = "sha256-LXCdF/cUYWy7mD3howFXexG0+fGfwFyKViuv9xZfgXc=";
    };

    nativeBuildInputs = [
      gradle_7
      makeWrapper
    ];

    mitmCache = gradle_7.fetchDeps {
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
