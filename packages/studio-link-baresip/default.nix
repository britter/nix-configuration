{
  lib,
  stdenv,
  fetchzip,
  fetchFromGitHub,
  zlib,
  openssl,
  libre,
  librem,
  pkg-config,
  gst_all_1,
  cairo,
  mpg123,
  alsa-lib,
  SDL2,
  libv4l,
  celt,
  libsndfile,
  srtp,
  ffmpeg,
  gsm,
  speex,
  portaudio,
  spandsp3,
  libuuid,
  libvpx,
  opus,
  flac,
}: let
  studio-link-app = fetchFromGitHub {
    owner = "Studio-Link";
    repo = "app";
    rev = "v21.07.0-stable";
    sha256 = "sha256-BjMZQDweQMM2TZuYoAGWE9eC/Vy8UnwDkkieY9TKpyg=";
  };
  # See https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/lib/functions.sh#L37-L43
  studio-link-webui = fetchzip {
    url = "https://download.studio.link/devel/v21.xx.x/v21.12.0-beta-3bb3eaf/webui.zip";
    sha256 = "sha256-7SkMQ8WM7vgFuiKS8+BFat4M/a9VNrWQKLMynKE4sEU=";
  };
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "baresip-studio-link";
    version = "1.0.0";
    src = fetchzip {
      url = "https://github.com/baresip/baresip/archive/v${finalAttrs.version}.tar.gz";
      sha256 = "sha256-HCnLidhuLP1QzFJ93jTk/+N86S+qZKnvtFHUAyUXPRM=";
    };

    # Link custom modules, see https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/lib/functions.sh#L123-L131
    postUnpack = ''
      rm -rf $sourceRoot/modules/g722
      ln -s ${studio-link-app}/src/modules/g722 $sourceRoot/modules/g722
      ln -s ${studio-link-app}/src/modules/slogging $sourceRoot/modules/slogging
      ln -s ${studio-link-app}/src/modules/effect $sourceRoot/modules/effect
      ln -s ${studio-link-app}/src/modules/effectonair $sourceRoot/modules/effectonair
      ln -s ${studio-link-app}/src/modules/apponair $sourceRoot/modules/apponair
      ln -s ${studio-link-app}/src/modules/slaudio $sourceRoot/modules/slaudio

      mkdir -p $sourceRoot/modules/webapp/assets
      cp -r ${studio-link-app}/src/modules/webapp/* $sourceRoot/modules/webapp/
      cp ${studio-link-webui}/headers/* $sourceRoot/modules/webapp/assets/
    '';

    # Patches are defined here: https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/lib/functions.sh#L110-L115
    patches = [
      "${studio-link-app}/dist/patches/config.patch"
      "${studio-link-app}/dist/patches/fix_check_telev_and_pthread.patch"
      "${studio-link-app}/dist/patches/dtls_aes256.patch"
      "${studio-link-app}/dist/patches/rtcp_mux_softphone.patch"
      "${studio-link-app}/dist/patches/fallback_dns.patch"
      "${studio-link-app}/dist/patches/baresip_audio_rtp_discard.patch"
    ];

    nativeBuildInputs = [pkg-config];

    buildInputs =
      [
        zlib
        openssl
        libre
        librem
        cairo
        mpg123
        alsa-lib
        SDL2
        libv4l
        celt
        libsndfile
        srtp
        ffmpeg
        gsm
        speex
        portaudio
        spandsp3
        libuuid
        libvpx
        opus
        flac
      ]
      ++ (with gst_all_1; [gstreamer gst-libav gst-plugins-base gst-plugins-bad gst-plugins-good]);

    # https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/build.sh#L123C18-L123C97
    preBuild = ''
      makeFlagsArray+=(MODULES="opus stdio ice g711 turn stun uuid auloop webapp effect g722 slogging dtls_srtp")
    '';

    makeFlags =
      [
        "LIBRE_MK=${libre}/share/re/re.mk"
        "LIBRE_INC=${libre}/include/re"
        "LIBRE_SO=${libre}/lib"
        "LIBREM_PATH=${librem}"
        "PREFIX=$(out)"
        "USE_VIDEO=1"
        "CCACHE_DISABLE=1"

        # https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/build.sh#L122
        "STATIC=1"
        # https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/build.sh#L125
        "libbaresip.a"
      ]
      ++ lib.optional (stdenv.cc.cc != null) "SYSROOT_ALT=${stdenv.cc.cc}"
      ++ lib.optional (stdenv.cc.libc != null) "SYSROOT=${stdenv.cc.libc}";

    # -DSLPLUGIN coming from https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/build.sh#L124C40-L124C50
    # Include of webapp coming from https://github.com/Studio-Link/app/blob/v21.07.0-stable/dist/lib/functions.sh#L136
    NIX_CFLAGS_COMPILE = ''
      -I${librem}/include/rem
      -I${gsm}/include/gsm
      -I${studio-link-app}/src/modules/webapp
      -DHAVE_INTTYPES_H
      -D__GLIBC__
      -D__need_timeval
      -D__need_timespec
      -D__need_time_t
      -DSLPLUGIN
    '';

    postInstall = ''
      mkdir -p $out/include
      cp include/* $out/include/

      mkdir -p $out/lib
      cp libbaresip.a $out/lib
    '';
  })
