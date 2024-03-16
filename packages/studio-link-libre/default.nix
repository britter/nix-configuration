{
  lib,
  stdenv,
  fetchzip,
  fetchpatch,
  openssl,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "studio-link-libre";
  version = "1.1.0";
  src = fetchzip {
    url = "https://github.com/baresip/re/archive/v${finalAttrs.version}.tar.gz";
    sha256 = "sha256-LZ45aS9uVN8j2jkmVkDv406iDYqtpuXni8H1bCCrmVw=";
  };

  # see https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/lib/functions.sh#L80-L83
  patches = [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/Studio-Link/app/v21.07.0-stable/dist/patches/bluetooth_conflict.patch";
      sha256 = "sha256-QuMst4avD18UeZJi5v0XI0Um8JMMR6f2/tNXD8IXrCA=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/Studio-Link/app/v21.07.0-stable/dist/patches/re_fix_authorization.patch";
      sha256 = "sha256-rZxsaRFnH0JSxiRIjHPmNx5q8rqRMKeXT8Grnua9hrU=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/Studio-Link/app/v21.07.0-stable/dist/patches/re_pull_66.diff";
      sha256 = "sha256-ksgmb00F4jfIG/qFEtiEK4nuENGUcAP9D22zPipMWmE=";
    })
  ];

  patchFlags = ["--ignore-whitespace" "-p1"];

  buildInputs = [zlib openssl];
  makeFlags =
    ["USE_ZLIB=1" "USE_OPENSSL=1" "PREFIX=$(out)"]
    ++ lib.optional (stdenv.cc.cc != null) "SYSROOT_ALT=${stdenv.cc.cc}"
    ++ lib.optional (stdenv.cc.libc != null) "SYSROOT=${lib.getDev stdenv.cc.libc}";
})
