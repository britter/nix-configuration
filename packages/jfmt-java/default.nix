{
  lib,
  fetchFromGitHub,
  graalvmPackages,
  maven_4,
  testers,
  jfmt-java,
}:
maven_4.buildMavenPackage {
  pname = "jfmt";
  version = "0.1.0-rc1";

  src = fetchFromGitHub {
    owner = "bmarwell";
    repo = "jfmt";
    # tag v0.1.0-rc1 points to a different commit than this commit which is on branch release/0.1.0-rc1 but not on main
    # this commit changes the version from 0.1.0-SNAPSHOT to 0.1.0-rc1, which indicates this is the release commit.
    rev = "9870374e6cf6b8e5f2142eafee1b8b671797ee92";
    sha256 = "sha256-RJHYiW31oZp86IohPfoBbX7GSp6teuCTJgjZmQ9EzKQ=";
  };
  mvnHash = "sha256-R1xsCVoabyf51fuf2sz6RbB8OKUiCCwc5f0Crg17lVE=";

  patches = [ ./0001-drop-JReleaser-from-build.patch ];

  # GraalVM CE with musl libc support; native-image is at $JAVA_HOME/bin/native-image
  # and the wrapper provides musl-gcc and musl C library paths automatically.
  mvnJdk = graalvmPackages.graalvm-ce-musl;
  doCheck = false;
  # -Pnative activates native-maven-plugin (runs native-image during package phase).
  # The dist-linux profile auto-activates on Linux and adds --static --libc=musl,
  # which works with graalvm-ce-musl's musl toolchain wrapper.
  # Spotless is skipped to avoid downloading the Eclipse JDT formatter at build time.
  mvnParameters = lib.escapeShellArgs [
    "-Dspotless.skip=true"
    "-Pnative"
    "-pl"
    "cli"
    "-am"
  ];

  nativeBuildInputs = [ graalvmPackages.graalvm-ce-musl ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    # The native-maven-plugin outputs the binary named after $${project.artifactId}-$${project.version}.
    # Exclude JARs and ZIPs created by maven-assembly-plugin in the same directory.
    find cli/target -maxdepth 1 -type f -perm /0111 -name 'jfmt*' \
      -exec install -m755 {} $out/bin/jfmt \;
    runHook postInstall
  '';

  passthru.tests = {
    version = testers.testVersion {
      package = jfmt-java;
      command = "jfmt --version";
    };
  };

  meta = {
    description = "jfmt is an opinionated java source code formatter for the command line ";
    homepage = "https://github.com/bmarwell/jfmt";
    license = lib.licenses.apsl20;
    maintainers = with lib.maintainers; [ britter ];
    mainProgram = "jfmt";
    platforms = lib.platforms.linux;
  };
}
