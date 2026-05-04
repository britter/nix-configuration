{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gh-get";
  version = "2.3.0";
  src = fetchFromGitHub {
    owner = "britter";
    repo = "gh-get";
    rev = "v${version}";
    sha256 = "sha256-zJoLahWCgKEJydUJZwdw+ZnWh/ciJJzYsVDi3JaXiyQ=";
  };
  vendorHash = "sha256-qzGBwWp9W2wZRuVGBGwIhnUZNaV+Dmzr0WSIFZMr6os=";
}
