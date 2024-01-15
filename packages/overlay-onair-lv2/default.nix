{
  baresip,
  libre,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "studio-link-onair-plugin";
  version = "latest";
  src = fetchFromGitHub {
    owner = "Studio-Link";
    repo = "overlay-onair-lv2";
    rev = "d58f3035208672f3a6f3e21bb6d0232c06cbab2d";
    sha256 = "sha256-bU1WdAqj7ZRTfwZPoajEtIeqUF0cM6IF4ektaCL6vew=";
  };

  postPatch = ''
    substituteInPlace build.sh \
      --replace "../my_include/libbaresip_onair.a" "${baresip}/lib/libbaresip.a" \
      --replace "../re/libre.a" "${libre}/lib/libre.a" \
      --replace "../rem/librem.a" ""
  '';

  buildPhase = ''
    patchShebangs --build build.sh
    ./build.sh
  '';
}
