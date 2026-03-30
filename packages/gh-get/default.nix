{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gh-get";
  version = "2.2.0";
  src = fetchFromGitHub {
    owner = "britter";
    repo = "gh-get";
    rev = "v${version}";
    sha256 = "sha256-67SfaPfV2zekxrg/j18D84QjlUqoUonOWDvIJdti3lA=";
  };
  vendorHash = "sha256-q9bwmwnA+HFRisC+WXt8eT/Y3tChTcdk4hV/mxRNYu0=";
}
