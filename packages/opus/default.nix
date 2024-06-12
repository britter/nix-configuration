{
  lib,
  stdenv,
  fetchzip,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "opus";
  version = "1.3.1";

  # https://github.com/Studio-Link/3rdparty/blob/v21.04.0/dist/build.sh#L147
  src = fetchzip {
    url = "https://archive.mozilla.org/pub/opus/opus-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-VyHmKoRXCJ0shVfUn6cX13b0fAXIQk0Z5NLZIfy8Gh4=";
  };

  configureFlags = [
    # https://github.com/Studio-Link/3rdparty/blob/v21.04.0/dist/build.sh#L163
    "--with-pic"
    # required to output libopus.a used in overlay-onair-lv2
    "--enable-static"
  ];

  makeFlags =
    ["PREFIX=$(out)"]
    ++ lib.optional (stdenv.cc.cc != null) "SYSROOT_ALT=${stdenv.cc.cc}"
    ++ lib.optional (stdenv.cc.libc != null) "SYSROOT=${lib.getDev stdenv.cc.libc}";
})
