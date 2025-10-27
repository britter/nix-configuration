{
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  jdk21,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kotlin-lsp";
  version = "0.253.10629";

  src = fetchzip {
    url = "https://download-cdn.jetbrains.com/kotlin-lsp/${finalAttrs.version}/kotlin-${finalAttrs.version}.zip";
    sha256 = "sha256-LCLGo3Q8/4TYI7z50UdXAbtPNgzFYtmUY/kzo2JCln0=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r $src $out/share
    chmod +x $out/share/kotlin-lsp.sh
    makeWrapper $out/share/kotlin-lsp.sh $out/bin/kotlin-lsp \
      --set JAVA_HOME ${jdk21}
  '';
})
