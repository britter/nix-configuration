{
  stdenv,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  jdk21,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kotlin-lsp";
  version = "262.2310.0";

  src = fetchzip {
    url = "https://download-cdn.jetbrains.com/kotlin-lsp/${finalAttrs.version}/kotlin-lsp-${finalAttrs.version}-linux-x64.zip";
    sha256 = "sha256-Bf2qkFpNhQC/Mz563OapmCXeKN+dTrYyQbOcF6z6b48=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    jdk21
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share}
    cp -r lib native kotlin-lsp.sh $out/share

    chmod +x $out/share/kotlin-lsp.sh
    substituteInPlace $out/share/kotlin-lsp.sh \
      --replace-fail 'LOCAL_JRE_PATH="$DIR/jre/Contents/Home"' 'LOCAL_JRE_PATH="${jdk21}"' \
      --replace-fail 'LOCAL_JRE_PATH="$DIR/jre"' 'LOCAL_JRE_PATH="${jdk21}"'
    makeWrapper $out/share/kotlin-lsp.sh $out/bin/kotlin-lsp

    runHook postInstall
  '';
})
