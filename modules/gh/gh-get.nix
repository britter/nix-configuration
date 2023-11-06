{pkgs, ...}: {
  gh-get = pkgs.stdenv.mkDerivation rec {
    name = "gh-get";
    pname = "gh-get";
    src = pkgs.fetchFromGitHub {
      owner = "britter";
      repo = "gh-get";
      rev = "v1.0.0";
      sha256 = "sha256-2o7Ugi8Ba3rso68Onc8tuh/RzWxZ9OTkdJYgo3K6+Gs=";
    };

    installPhase = ''
      mkdir -p $out/bin
      cp gh-get $out/bin
    '';
  };
}
