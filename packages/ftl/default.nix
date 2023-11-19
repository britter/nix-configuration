{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  gnum4,
  unixtools,
  readline,
  nettle,
  gmp,
  libidn,
}:
stdenv.mkDerivation rec {
  pname = "ftl";
  version = "5.23";

  src = fetchFromGitHub {
    owner = "pi-hole";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-kMOGf6Qsayhr7uuFp9cGqJFubpFwlhJjVxEdpC1mO/M=";
  };

  nativeBuildInputs = [cmake gnum4 unixtools.xxd];

  buildInputs = [readline libidn nettle];
}
