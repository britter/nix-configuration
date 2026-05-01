{
  fetchurl,
  maven,
  callPackage,
}:
maven.overrideAttrs (
  final: _prev: {
    version = "4.0.0-rc-5";
    src = fetchurl {
      url = "mirror://apache/maven/maven-4/${final.version}/binaries/apache-maven-${final.version}-bin.tar.gz";
      hash = "sha256-7OalyZ09BBx25/7RgU656jogoSC8s8I1pz0sTo2xbKE=";
    };
    passthru.buildMavenPackage = callPackage ./build-maven-package.nix {
      maven = final.finalPackage;
    };
  }
)
