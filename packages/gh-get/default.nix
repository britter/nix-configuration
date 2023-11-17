{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "gh-get";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "britter";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-2o7Ugi8Ba3rso68Onc8tuh/RzWxZ9OTkdJYgo3K6+Gs=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp gh-get $out/bin
  '';
}

