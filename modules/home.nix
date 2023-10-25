{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gradle
  ];
  home.sessionVariables = {
    JDK8 = "${pkgs.jdk8}";
  };

  imports = [
    ./git
    ./gpg
    ./helix
    ./terminal
  ];

  programs.firefox.enable = true;

  programs.gh = {
    enable = true;

    extensions =
      let
        gh-get = with pkgs; stdenv.mkDerivation rec {
          name = "gh-get";
          pname = "gh-get";
          src = fetchFromGitHub {
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
      in
      [ gh-get ];
  };

  programs.java = {
    enable = true;
    package = pkgs.jdk17;
  };
}
