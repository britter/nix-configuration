{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  alsa-lib,
  freetype,
  juce,
  libX11,
  libXcursor,
  libXext,
  libXinerama,
  libXrandr,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ultraschall-soundboard";
  version = "8a7a538831d8dbf7689b47611d218560762ae869";

  src = fetchFromGitHub {
    owner = "Ultraschall";
    repo = "ultraschall-soundboard";
    rev = "${finalAttrs.version}";
    sha256 = "sha256-ddvfUI08h8cKJ2Hoac0unEsQryjPhZGnWpIm/pg0jUk=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    alsa-lib
    freetype
    juce
    libX11
    libXcursor
    libXext
    libXinerama
    libXrandr
  ];
  # configureFlags = [
  #   "-Bbuild"
  #   "-GNinja"
  #   "-Wno-dev"
  #   "-DCMAKE_BUILD_TYPE=Release"
  # ];

  # cmakeFlags = [
  #   "--build"
  #   "build"
  #   "--target"
  #   "UltraschallSoundboard_VST3"
  #   "--config"
  #   "Release"
  #   "-j"
  # ];
})
