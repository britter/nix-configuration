{
  buildGoModule,
  fetchFromGitHub,
  fetchpatch,
  ...
}:
buildGoModule rec {
  pname = "fritzbox-cloudflare-dyndns";
  version = "1.2.2";
  src = fetchFromGitHub {
    owner = "cromefire";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-T3YlQdrr+XJ4rlulmSyq9zeIu1iKNjggN+yhGYjvpw4=";
  };
  vendorHash = "sha256-Gsoq+41J3aC43eDFZvqDtw5CaEmkeAKMmqOPttEJdhQ=";
  patches = [
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/cromefire/fritzbox-cloudflare-dyndns/pull/29.patch";
      sha256 = "sha256-M3RPNTSv/qJhnB7aZ3QZOUgecgC+ycQAwsHKO3fJOmc=";
    })
  ];
}
