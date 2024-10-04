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
    (fetchpatch {
      url = "https://github.com/cromefire/fritzbox-cloudflare-dyndns/commit/763df385e52549fea64b50c5e5a32b94fea0caf9.patch";
      sha256 = "sha256-nN0RbFQta4WGpWN2bI1zalVUdsVKz4ULoWPo318uGoo=";
    })
    (fetchpatch {
      url = "https://github.com/cromefire/fritzbox-cloudflare-dyndns/commit/2c0da7581ff4c879e2f38f8c2ba2ba8190e29c99.patch";
      sha256 = "sha256-B3fdVR0NoSC0bqkWnnAYs9+3mGgmc1eUldYqwN7N3co=";
    })
    (fetchpatch {
      url = "https://github.com/britter/fritzbox-cloudflare-dyndns/commit/486ae93a2afa637799e0c43d732a162a502a2fac.patch";
      sha256 = "sha256-fxaWPgcn258l73J1oJC8llzzIrjJHkTRG8Y8RY6GvH0=";
    })
  ];
}
