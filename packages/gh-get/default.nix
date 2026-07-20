{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gh-get";
  version = "2.5.0";
  src = fetchFromGitHub {
    owner = "britter";
    repo = "gh-get";
    rev = "v${version}";
    sha256 = "sha256-T2ZeyhVhkgXEevx2UxAS992kLUhk1kFIpOYT1/OdDJ4=";
  };
  vendorHash = "sha256-qzGBwWp9W2wZRuVGBGwIhnUZNaV+Dmzr0WSIFZMr6os=";
}
