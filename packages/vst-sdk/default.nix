{
  stdenvNoCC,
  fetchzip,
  fetchpatch,
}:
stdenvNoCC.mkDerivation {
  pname = "vst-sdk";
  version = "2.4";
  src = fetchzip {
    url = "https://download.studio.link/tools/vstsdk367_03_03_2017_build_352.zip";
    sha256 = "sha256-9HUbAlQc815SEck98xinXexJhpUi+/CXUkAUqCOJhM0=";
  };

  postUnpack = ''
    mv $sourceRoot/VST2_SDK $sourceRoot/vstsdk2.4
  '';

  patches = [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/Studio-Link/overlay-vst/master/vst2_linux.patch";
      sha256 = "sha256-l9QGYDUiQUaFmGTAfNvMZsZLZ70/aSU6wz8ACsRJPQM=";
    })
  ];

  patchFlags = ["-p0"];

  installPhase = ''
    mkdir -p $out/include
    cp -r vstsdk2.4/* $out/include/
  '';
}
