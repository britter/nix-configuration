{
  stdenv,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  jdk25,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kotlin-lsp";
  version = "262.8190.0";

  src = fetchzip {
    url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${finalAttrs.version}/kotlin-server-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-kxV0AU1TEi7U84boc45V7GJNJzo3uWraHEo6q4Kd9+U=";
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    jdk25
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/kotlin-lsp
    cp -r bin build.txt kotlin-lsp.sh lib license modules plugins product-info.json $out/share/kotlin-lsp
    ln -s ${jdk25}/lib/openjdk $out/share/kotlin-lsp/jbr

    makeWrapper $out/share/kotlin-lsp/bin/intellij-server $out/bin/kotlin-lsp

    runHook postInstall
  '';

  # kotlin-lsp has no --version, so instead of versionCheckHook drive a
  # minimal LSP initialize handshake over stdio and assert the server
  # replies with a framed JSON-RPC message. This exercises the JVM launch
  # and the patched native libraries, which is where breakage tends to hide.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    req='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"rootUri":null,"capabilities":{}}}'
    printf 'Content-Length: %d\r\n\r\n%s' "''${#req}" "$req" \
      | timeout 120 $out/bin/kotlin-lsp --stdio > response.txt 2>/dev/null || true

    grep -q '"jsonrpc"' response.txt || {
      echo "kotlin-lsp did not respond to an LSP initialize request" >&2
      exit 1
    }

    runHook postInstallCheck
  '';
})
