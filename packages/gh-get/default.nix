{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gh-get";
  version = "2.1.0";
  src = fetchFromGitHub {
    owner = "britter";
    repo = "gh-get";
    rev = "v${version}";
    sha256 = "sha256-tViHABeAVxrQK4oJTeEZV1wWcaif+9Ew5LjRK9FnGgI=";
  };
  vendorHash = "sha256-2qgetyUwmoGetgpef1+JU9Av83/MpUfQGOLDxSzoa1E=";
}
