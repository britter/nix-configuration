{
  lib,
  callPackage,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  makeWrapper,
  python313,
  p7zip,
  file, # provides libmagic for python-magic
}:
let
  version = "4.9.2";

  src = fetchFromGitHub {
    owner = "rommapp";
    repo = "romm";
    tag = version;
    hash = "sha256-mXb7mJF4QVWZIqrTQaKmGYe4ewppbRhyQC0UcIloEDY=";
  };

  frontend = callPackage ./frontend.nix { inherit src version; };

  emulatorjs =
    let
      ejsVersion = "4.2.3";
    in
    stdenvNoCC.mkDerivation {
      pname = "emulatorjs";
      version = ejsVersion;
      src = fetchurl {
        url = "https://github.com/EmulatorJS/EmulatorJS/releases/download/v${ejsVersion}/${ejsVersion}.7z";
        hash = "sha256-B9RRvAb6OtBKsw2blOtjrDStC6vuUtYDV7ACvejzhQs=";
      };
      nativeBuildInputs = [ p7zip ];
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out
        7z x -y "$src" -o"$out"
      '';
    };

  python = python313.override {
    self = python;
    packageOverrides = pyfinal: _pyprev: {
      # ROMM pins rq-scheduler to a git fork that adds username/SSL support.
      # Track upstream pyproject.toml for the exact rev/branch.
      # nixpkgs's python313Packages.crontab is actually doctormo's
      # python-crontab; rq-scheduler depends on Josiah Carlson's separate
      # `crontab` package on PyPI, so we provide it ourselves.
      jc-crontab = pyfinal.buildPythonPackage rec {
        pname = "crontab";
        version = "1.0.4";
        pyproject = true;
        src = pyfinal.fetchPypi {
          inherit pname version;
          hash = "sha256-cVsOXhBbxiyWg8u5PBzFgh4Ho+KNF0BFdtItunqJbJI=";
        };
        build-system = [ pyfinal.setuptools ];
        doCheck = false;
        pythonImportsCheck = [ "crontab" ];
      };

      rq-scheduler = pyfinal.buildPythonPackage {
        pname = "rq-scheduler";
        version = "unstable-2025-09-23";
        pyproject = true;
        src = fetchFromGitHub {
          owner = "adamantike";
          repo = "rq-scheduler";
          rev = "feat/script-options-username-ssl";
          hash = "sha256-VOgMuzSDwCIWOlWc2+dxZHXqO3IigTi0F7ZRAzbgzLE=";
        };
        build-system = [ pyfinal.setuptools ];
        dependencies = [
          pyfinal.rq
          pyfinal.jc-crontab
          pyfinal.python-dateutil
        ];
        doCheck = false;
      };

      strsimpy = pyfinal.buildPythonPackage rec {
        pname = "strsimpy";
        version = "0.2.1";
        pyproject = true;
        src = pyfinal.fetchPypi {
          inherit pname version;
          hash = "sha256-CELrV/evhsiCpZobyHIewlgKJn5WP9BQPO0pcgQDcsk=";
        };
        build-system = [ pyfinal.setuptools ];
        doCheck = false;
      };

      zipfile-inflate64 = pyfinal.buildPythonPackage rec {
        pname = "zipfile-inflate64";
        version = "0.1";
        format = "wheel";
        src = pyfinal.fetchPypi {
          pname = "zipfile_inflate64";
          inherit version format;
          python = "py3";
          dist = "py3";
          hash = "sha256-tETzrqkEBh1wLtvtWPlS5UShnc8g8u2EvYic9Ea4e30=";
        };
        dependencies = [ pyfinal.inflate64 ];
        doCheck = false;
      };
    };
  };

  pythonEnv = python.withPackages (
    ps: with ps; [
      aiohttp
      alembic
      anyio
      asyncssh
      authlib
      bcrypt
      colorama
      defusedxml
      fastapi
      fastapi-pagination
      gunicorn
      httpx
      itsdangerous
      joserfc
      mariadb
      mysql-connector
      mutagen
      opentelemetry-api
      opentelemetry-distro
      opentelemetry-exporter-otlp
      opentelemetry-instrumentation-aiohttp-client
      opentelemetry-instrumentation-fastapi
      opentelemetry-instrumentation-httpx
      opentelemetry-instrumentation-redis
      opentelemetry-instrumentation-sqlalchemy
      passlib
      pillow
      psycopg
      pydantic
      pydash
      python-dotenv
      python-magic
      python-multipart
      python-socketio
      pyyaml
      redis
      rq
      rq-scheduler
      sentry-sdk
      sqlalchemy
      starlette
      streaming-form-data
      strsimpy
      ua-parser
      unidecode
      uvicorn
      uvicorn-worker
      watchfiles
      yarl
      zipfile-inflate64
    ]
  );
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "romm";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/romm $out/bin
    cp -r backend $out/share/romm/backend
    cp -r ${frontend} $out/share/romm/frontend
    chmod -R u+w $out/share/romm/frontend
    # Upstream's Dockerfile copies frontend/assets/ (source-level static
    # files: platform logos, dashboard icons, scraper logos, ...) on top
    # of the built dist. The SPA references them by unhashed path.
    cp -r frontend/assets/. $out/share/romm/frontend/assets/
    chmod -R u+w $out/share/romm/frontend/assets
    # frontend/assets/emulatorjs only holds three placeholder SVGs;
    # replace it with the actual EmulatorJS bundle.
    rm -rf $out/share/romm/frontend/assets/emulatorjs
    ln -s ${emulatorjs} $out/share/romm/frontend/assets/emulatorjs

    # Entry points: cd into backend so relative paths (alembic.ini, migrations,
    # config templates) resolve as they do in the official Docker image.
    makeWrapper ${pythonEnv}/bin/gunicorn $out/bin/romm-api \
      --chdir $out/share/romm/backend \
      --prefix PYTHONPATH : $out/share/romm/backend \
      --prefix PATH : ${lib.makeBinPath [ p7zip ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ file ]} \
      --add-flags "--worker-class uvicorn_worker.UvicornWorker main:app"

    makeWrapper ${pythonEnv}/bin/rq $out/bin/romm-worker \
      --chdir $out/share/romm/backend \
      --prefix PYTHONPATH : $out/share/romm/backend \
      --prefix PATH : ${lib.makeBinPath [ p7zip ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ file ]} \
      --add-flags "worker --path $out/share/romm/backend"

    makeWrapper ${pythonEnv}/bin/rqscheduler $out/bin/romm-scheduler \
      --chdir $out/share/romm/backend \
      --prefix PYTHONPATH : $out/share/romm/backend \
      --add-flags "--path $out/share/romm/backend"

    makeWrapper ${pythonEnv}/bin/alembic $out/bin/romm-migrate \
      --chdir $out/share/romm/backend \
      --prefix PYTHONPATH : $out/share/romm/backend \
      --add-flags "upgrade head"

    makeWrapper ${pythonEnv}/bin/python3 $out/bin/romm-startup \
      --chdir $out/share/romm/backend \
      --prefix PYTHONPATH : $out/share/romm/backend \
      --add-flags "startup.py"

    runHook postInstall
  '';

  passthru = {
    inherit frontend pythonEnv;
    tests.romm-vm-test = callPackage ./nixos-test.nix {
      romm = finalAttrs.finalPackage;
    };
  };

  meta = with lib; {
    description = "ROMM — a self-hosted ROM manager and player";
    homepage = "https://github.com/rommapp/romm";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    mainProgram = "romm-api";
  };
})
