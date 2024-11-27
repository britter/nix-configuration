{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gh-get";
  version = "2.0.0";
  src = fetchFromGitHub {
    owner = "britter";
    repo = "gh-get";
    rev = "v${version}";
    sha256 = "sha256-9YWftzKNKPxs06yTDvFPpcGHXLzWiNfHcA6kkz6zt0g=";
  };
  vendorHash = "sha256-2qgetyUwmoGetgpef1+JU9Av83/MpUfQGOLDxSzoa1E=";
}
