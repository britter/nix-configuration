{ lib, stdenv, fetchFromGitHub, cmake, readline, nettle, gmp, libidn }:

stdenv.mkDerivation rec {
  pname = "ftl";
  version = "5.23";

  src = fetchFromGitHub {
    owner = "pi-hole";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-kMOGf6Qsayhr7uuFp9cGqJFubpFwlhJjVxEdpC1mO/M=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ libidn nettle readline ];

  cmakeFlags = [
    "-DLIBHOGWEED=${nettle}/lib"
    "-DLIBNETTLE=${nettle}/lib"
    "-DLIBGMP=${gmp}/lib"
    "-DLIBIDN=${libidn}/bin"
  ];
}
