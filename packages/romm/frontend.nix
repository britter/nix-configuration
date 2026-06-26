{
  lib,
  buildNpmPackage,
  nodejs_24,
  src,
  version,
}:
buildNpmPackage {
  pname = "romm-frontend";
  inherit version src;

  sourceRoot = "${src.name}/frontend";

  npmDepsHash = "sha256-jKZ9zuWaQz2oOioMoN4IQc/jhfyHQQ/v4NzHrOQZLvM=";

  makeCacheWritable = true;

  nodejs = nodejs_24;

  # `npm run build` chains `prebuild` (tsx scripts/build-tokens.ts) and `vite build`.
  # Output lands in ./dist.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/. $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Vue/Vite frontend for ROMM";
    homepage = "https://github.com/rommapp/romm";
    license = licenses.agpl3Only;
    platforms = platforms.all;
  };
}
