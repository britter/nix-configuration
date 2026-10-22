{ config, inputs, ... }:
{
  flake.overlays = {
    local-pkgs = final: _prev: import ../../packages { pkgs = final; };

    # Remove entries here once the referenced nixpkgs PR has been merged and
    # is in nixos-unstable.
    fixes = final: prev: {
      # Backport of https://github.com/NixOS/nixpkgs/pull/576874: fabric 3.2.3
      # is marked broken with invoke >= 3 (invoke was bumped to 3.0.3 in
      # nixpkgs without a fabric release supporting it). azure-cli (installed
      # by seeq-support) depends on fabric, so it breaks the evaluation of the
      # man page database. The fix updates fabric to an unreleased snapshot
      # that supports invoke v3 and drops the broken marker.
      #
      # Applied via pythonPackagesExtensions (not python3.override) because
      # azure-cli re-overrides the interpreter with its own packageOverrides,
      # which would drop a per-interpreter override.
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (_pyfinal: pyprev: {
          fabric = pyprev.fabric.overrideAttrs (_old: {
            version = "3.2.3-unstable-2026-04-07";
            src = final.fetchFromGitHub {
              owner = "fabric";
              repo = "fabric";
              rev = "cc098ad475dbbe2e10aba72692d83aee58919570";
              hash = "sha256-Z1tGcjdLrzbqcbS6XwapSgDNpyLbBiO21yeqi7XhbpQ=";
            };
            meta = (_old.meta or { }) // {
              # https://github.com/fabric/fabric/issues/2376
              broken = false;
            };
          });
        })
      ];

      # Backport of https://github.com/NixOS/nixpkgs/pull/575818: the kmod
      # installs the bare module with `install` instead of `modules_install`.
      # Kernel modules are signed with kmodigest during modules_install,
      # which produces a per-module certificate next to the module, and the
      # NixOS module tree aggregator (pkgs/os-specific/linux/kmod/aggregator.nix)
      # concatenates those certificates of external modules into
      # `modules.cer`. The custom installPhase drops the certificate, so the
      # framework-13 toplevel fails with `cat: extra/framework_laptop.ko.cer:
      # No such file or directory`. Install through `modules_install`, which
      # signs the module and ships it together with its certificate.
      linuxPackages_latest = prev.linuxPackages_latest.extend (
        _kfinal: kprev: {
          framework-laptop-kmod = kprev.framework-laptop-kmod.overrideAttrs (old: {
            makeFlags = old.makeFlags ++ [
              "INSTALL_MOD_PATH=${placeholder "out"}"
              "INSTALL_MOD_DIR=extra"
              "DEPMOD=true"
            ];
            installPhase = ''
              runHook preInstall
              local flagsArray=()
              concatTo flagsArray makeFlags installTargets=modules_install
              make "''${flagsArray[@]}"
              runHook postInstall
            '';
          });
        }
      );

      # calibre's test suite fails with `ModuleNotFoundError: No module named
      # 'speechd'`: the speechd package in nixos-unstable never builds its
      # Python bindings, because its configure script cannot find a Python
      # interpreter (it is only in buildInputs, and speechd sets strictDeps).
      # Nothing that depends on speechd can be fixed without rebuilding the
      # world, so disable speech support instead. This drops the
      # speech-dispatcher TTS integration (and piper-tts) from calibre until
      # the packaging bug is fixed upstream.
      calibre = prev.calibre.override {
        speechSupport = false;
      };
    };

    default = inputs.nixpkgs.lib.composeManyExtensions [
      config.flake.overlays.local-pkgs
      config.flake.overlays.fixes
      inputs.nur.overlays.default
      inputs.llm-agents.overlays.shared-nixpkgs
    ];
  };
}
