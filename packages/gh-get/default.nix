{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gh-get";
  version = "2.4.0";
  src = fetchFromGitHub {
    owner = "britter";
    repo = "gh-get";
    rev = "v${version}";
    sha256 = "sha256-3J8vrnp/H4CZkectbrumJobDOS5sponR72J6EueMWJU=";
  };
  vendorHash = "sha256-qzGBwWp9W2wZRuVGBGwIhnUZNaV+Dmzr0WSIFZMr6os=";
}
