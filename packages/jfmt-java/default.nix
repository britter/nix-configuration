{
  lib,
  fetchFromGitHub,
  jdk25_headless,
  makeWrapper,
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
  mvnHash = "sha256-FUK/CmtQdA5+G4EAlqFMImzZS3vLtd355qK9ALPZlYU=";

  mvnJdk = jdk25_headless;
  doCheck = false;
  # disable spotless because the build is configured to run spotless apply in
  # process-resources and it tries to download the eclipse jdt formatter from
  # downloads.eclipse.org at runtime of the main derivation
  mvnParameters = lib.escapeShellArgs [
    "-Dspotless.skip=true"
    "-Prelease"
    "-pl"
    "cli"
    "-am"
  ];

  nativeBuildInputs = [
    makeWrapper
    # required by jfmt build to generate completion scripts using maven-exec-plugin
    jdk25_headless
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/
    cp -r cli/target/jreleaser/assemble/jfmt/java-archive/work/jfmt-*/* $out/

    # remove timestamped line from script
    sed -i '/Generated with JReleaser/d' $out/bin/jfmt
    # drop unneeded windows script
    rm $out/bin/jfmt.bat

    wrapProgram $out/bin/jfmt \
      --set JAVA_HOME ${jdk25_headless}

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
  };
}
