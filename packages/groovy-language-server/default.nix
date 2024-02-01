{
  writeText,
  stdenv,
  fetchFromGitHub,
  gradle_7,
  jdk,
  makeWrapper,
  perl,
}: let
  # see https://github.com/brianmcgee/nix-gradle-sample/blob/2c4a48d46286abbfe2b2c3dc7c6720f8e1efbab0/flake.nix#L148-L169
  version = "unstable-2024-02-01";

  src = fetchFromGitHub {
    owner = "GroovyLanguageServer";
    repo = "groovy-language-server";
    rev = "4866a3f2c180f628405b1e4efbde0949a1418c10";
    sha256 = "sha256-LXCdF/cUYWy7mD3howFXexG0+fGfwFyKViuv9xZfgXc=";
  };

  deps = stdenv.mkDerivation {
    pname = "groovy-language-server-deps";
    inherit version src;

    nativeBuildInputs = [gradle_7 perl];

    buildPhase = ''
      export GRADLE_USER_HOME=$(mktemp -d)
      gradle --no-daemon --console=plain shadowJar
    '';

    # perl code mavenizes paths (com.squareup.okio/okio/1.13.0/a9283170b7305c8d92d25aff02a6ab7e45d06cbe/okio-1.13.0.jar -> com/squareup/okio/okio/1.13.0/okio-1.13.0.jar)
    # reproducible by sorting
    installPhase = ''
      find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\)' \
        | LC_ALL=C sort \
        | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
        | sh
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-skkweZ9bZ/Rx/Eh0sla1W8tjoAXwerWM5y9BNjxIwaI=";
  };
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "groovy-language-server";
    inherit version src;

    nativeBuildInputs = [gradle_7 makeWrapper];

    # Point to our local deps repo
    gradleInit = writeText "init.gradle" ''
      logger.lifecycle 'Replacing Maven repositories with ${deps}...'
      gradle.projectsLoaded {
        rootProject.allprojects {
          buildscript {
            repositories {
              clear()
              maven { url '${deps}' }
            }
          }
          repositories {
            clear()
            maven { url '${deps}' }
          }
        }
      }
      settingsEvaluated { settings ->
        settings.pluginManagement {
          repositories {
            maven { url '${deps}' }
          }
        }
      }
    '';

    buildPhase = ''
      runHook preBuild

      export GRADLE_USER_HOME=$(mktemp -d)
      gradle --offline --init-script ${finalAttrs.gradleInit} --no-daemon --console=plain shadowJar

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share
      # project does not set rootProject.name via settings.gradle, hence the resulting jar's name is 'source-all.jar'
      cp build/libs/source-all.jar $out/share/groovy-language-server-all.jar
      makeWrapper ${jdk}/bin/java $out/bin/groovy-language-server \
        --add-flags "-jar $out/share/groovy-language-server-all.jar"

      runHook postInstall
    '';
  })
