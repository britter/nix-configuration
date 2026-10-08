{
  stdenv,
  fetchFromGitHub,
  gradle_9,
  graalvmPackages,
}:
let
  graalvm = graalvmPackages.graalvm-ce-musl;
  self = stdenv.mkDerivation (finalAttrs: {
    pname = "testlens";
    version = "1.0.0";

    src = fetchFromGitHub {
      owner = "testlens-app";
      repo = "cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-ThhnxlMzsUSsymtg843AMYuxv17hqsTeyC7mwIr+4wA=";
    };

    nativeBuildInputs = [
      gradle_9
      graalvm
    ];

    # if the package has dependencies, mitmCache must be set
    mitmCache = gradle_9.fetchDeps {
      pkg = finalAttrs.finalPackage;
      data = ./deps.json;
    };

    # this is required for using mitm-cache on Darwin
    __darwinAllowLocalNetworking = true;

    gradleFlags = [ "-Dorg.gradle.java.home=${graalvm}" ];

    gradleUpdateTask = "generateResourcesConfigFile";
    gradleBuildTask = "nativeCompile";
    doCheck = false;

    installPhase = ''
      mkdir -p $out/bin
      cp build/native/nativeCompile/testlens $out/bin/testlens
    '';
  });
in
self
