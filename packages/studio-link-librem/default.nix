{
  lib,
  stdenv,
  fetchurl,
  zlib,
  openssl,
  libre,
}:
stdenv.mkDerivation (finalAttrs: {
  version = "0.6.0";
  pname = "studio-link-librem";
  src = fetchurl {
    url = "https://github.com/creytiv/rem/archive/v${finalAttrs.version}.tar.gz";
    sha256 = "0b17wma5w9acizk02isk5k83vv47vf1cf9zkmsc1ail677d20xj1";
  };
  buildInputs = [zlib openssl libre];
  makeFlags =
    [
      "LIBRE_MK=${libre}/share/re/re.mk"
      "LIBRE_INC=${libre}/include/re"
      "PREFIX=$(out)"
    ]
    ++ lib.optional (stdenv.cc.cc != null) "SYSROOT_ALT=${lib.getDev stdenv.cc.cc}"
    ++ lib.optional (stdenv.cc.libc != null) "SYSROOT=${lib.getDev stdenv.cc.libc}";
})
