_: {

  flake.modules.homeManager.nixpkgs-tools =
    { pkgs, ... }:
    let

      # A mostly transparent wrapper: arguments go to `nixpkgs-review`
      # untouched, except for the two flags this script consumes itself:
      # `--local-workers N` and `--cleanup-store` / `--no-cleanup-store`.
      # What it adds on top is the community builders and the cleanup
      # afterwards.
      #
      # `max-jobs = 0` (the default via `--local-workers 0`) keeps the laptop
      # out of the build entirely, which is the whole point of reaching for
      # the community machines. The garbage collection afterwards is what
      # keeps their output from lingering: nixpkgs-review builds with
      # `--no-link` and leaves plain symlinks in ~/.cache/nixpkgs-review,
      # none of which are GC roots, so once the review shell has exited every
      # path the builders sent is unreachable. Left in the store it would
      # stay valid forever and could be reused by a later build instead of
      # being fetched from a signed cache.
      nixpkgs-review-remote = pkgs.writeShellApplication {
        name = "nixpkgs-review-remote";
        runtimeInputs = [
          pkgs.glow
          pkgs.delta
          pkgs.nixpkgs-review
        ];
        text = ''
              local_workers=0
              cleanup_store=1

              review_args=()
                while [ "$#" -gt 0 ]; do
                  case "$1" in
                      --local-workers)
                    [ "$#" -ge 2 ] || {
                        echo "nixpkgs-review-remote: --local-workers requires an argument" >&2
                      exit 1
                    }
                    local_workers=$2
                    shift 2
                    ;;
                  --local-workers=*)
                    local_workers=''${1#*=}
                shift
                ;;
              --cleanup-store)
                cleanup_store=1
                shift
                ;;
              --no-cleanup-store)
                cleanup_store=0
                shift
                ;;
              *)
                review_args+=("$1")
                shift
                ;;
              esac
          done

          # Configure the builders through the environment rather than through
            # `--build-args`, so the remaining arguments belong to nixpkgs-review
            # alone and none of its subcommands or flags are off limits.
            export NIX_CONFIG="builders = @/etc/nix/machines
              max-jobs = $local_workers"

              set +e
              nixpkgs-review "''${review_args[@]}"
                review_status=$?
              set -e

              if [ "$cleanup_store" -eq 1 ]; then
                  echo "Dropping store paths received from the community builders..."
                  nix-collect-garbage
                else
                  echo
                echo "NOTE: --no-cleanup-store was given, the local store now contains"
                  echo "binaries built on the community builders. These paths are unsigned,"
                  echo "so running 'nix-collect-garbage' manually is recommended once they"
                  echo "are no longer needed."
                fi
                exit $review_status
        '';
      };
      gradle-packages =
        pkgs.writers.writePython3Bin "gradle_packages" { flakeIgnore = [ "E501" ]; }
          # python
          ''
            """List the attribute names of all gradle consumers (packages using
            gradle*.fetchDeps), one per line, for piping into nixpkgs-review(-remote).

            Run from the root of a nixpkgs checkout, e.g.:

                gradle_packages | sed 's/^/-p /' | xargs -r nixpkgs-review-remote rev HEAD
            """
            import os
            import re
            import sys
            from pathlib import Path

            # `mitmCache = gradle.fetchDeps`, with variations as seen in the
            # tree: a version suffix (`gradle_8`, `gradle_jdk17`) or a
            # `finalAttrs.` qualifier.
            MITM_CACHE = re.compile(
                r"mitmCache\s*=\s*(?:finalAttrs\.)?gradle(?:_\w+)?\.fetchDeps"
            )

            # path (relative to the nixpkgs root) -> correct top-level attribute path
            OVERRIDES = {
                "pkgs/tools/security/ghidra/build.nix": "ghidra",
                "pkgs/tools/security/ghidra/extensions/reva/default.nix": "ghidra-extensions.reva",
                "pkgs/tools/security/ghidra/extensions/kaiju/default.nix": "ghidra-extensions.kaiju",
                "pkgs/tools/security/ghidra/extensions/ghidra-delinker-extension/default.nix": "ghidra-extensions.ghidra-delinker-extension",
                "pkgs/by-name/ap/apkeditor/smali/default.nix": "apkeditor.passthru.deps.smali",
                "pkgs/by-name/ap/apkeditor/jcommand/default.nix": "apkeditor.passthru.deps.jcommand",
                "pkgs/by-name/ap/apkeditor/arsclib/default.nix": "apkeditor.passthru.deps.arsclib",
                "pkgs/by-name/ke/keycloak/apple-identity-provider-keycloak/default.nix": "keycloak.passthru.plugins.apple-identity-provider-keycloak",
                "pkgs/by-name/sh/shattered-pixel-dungeon/generic.nix": "shattered-pixel-dungeon",
            }

            root = Path(".")

            # Only meaningful inside a nixpkgs checkout, where the gradle
            # consumers live under `pkgs/`.
            if not (root / "pkgs").is_dir():
                sys.exit("Has to be run from inside a nixpkgs checkout")


            def find_mitm_cache_files(pkgs):
                """Yield the paths of all .nix files under `pkgs` containing a
                `mitmCache = gradle*.fetchDeps` assignment."""
                for dirpath, dirnames, filenames in os.walk(pkgs):
                    dirnames[:] = [d for d in dirnames if d != ".git"]
                    for filename in filenames:
                        if not filename.endswith(".nix"):
                            continue
                        path = os.path.join(dirpath, filename)
                        with open(path, encoding="utf-8", errors="replace") as fh:
                            if MITM_CACHE.search(fh.read()):
                                yield path


            files = sorted(find_mitm_cache_files(root / "pkgs"))

            attrs = set()
            for f in files:
                if f in OVERRIDES:
                    attrs.add(OVERRIDES[f])
                    continue
                parts = f.removesuffix(".nix").split("/")
                if parts[:2] == ["pkgs", "by-name"]:
                    name, rest = parts[3], parts[4:]
                    while rest and rest[-1] in ("package", "default"):
                        rest = rest[:-1]
                    attrs.add(".".join([name] + rest))
                else:
                    attrs.add(".".join(parts[3:]))

            print("\n".join(sorted(attrs)))
          '';
    in
    {
      home.packages = [
        pkgs.nixpkgs-review
        nixpkgs-review-remote
        gradle-packages
      ];
    };
}
