{
  baresip,
  libre,
  librem,
  stdenv,
  fetchFromGitHub,
  vst-sdk,
  openssl,
  opus,
}:
stdenv.mkDerivation rec {
  pname = "studio-link-plugin";
  version = "latest";
  src = fetchFromGitHub {
    owner = "Studio-Link";
    repo = "overlay-vst";
    rev = "8efd287cb86ee601fda8054456da038f1128808a";
    sha256 = "sha256-xP99uqdr4LmCQEydiVX3SHVYizHo+2pmjOLNVz62kGg=";
  };

  postPatch = ''
    ls -la
    rm Makefile
    mv Makefile.linux Makefile
    substituteInPlace Makefile \
      --replace "vstsdk2.4" "${vst-sdk}/include" \
      --replace "../baresip/libbaresip.a" "${baresip}/lib/libbaresip.a" \
      --replace "../re/libre.a" "${libre}/lib/libre.a" \
      --replace "../rem/librem.a" "${librem}/lib/librem.a"
  '';

  buildInputs = [
    baresip
    libre
    librem
    openssl
    opus
  ];
}
