{
  writeShellApplication,
  patchelf,
  ncurses,
  stdenv,
}:
writeShellApplication {
  name = "fix-gradle-console";

  runtimeInputs = [ patchelf ];

  text = ''
    # Fix Gradle's broken rich console auto-detection caused by bare native
    # libraries in the ~/.gradle/native cache (see
    # britter.dev/blog/2026/05/26/gradle-rich-console-nix/).
    #
    # Wrapper-downloaded Gradle distributions extract .so files without a
    # RUNPATH; a nixpkgs-built JDK's dlopen then can't resolve their
    # ncurses dependencies. Patch the RUNPATH in place so the cached
    # libraries load. Works for any Gradle version sharing the cache.

    nativeDir="''${GRADLE_USER_HOME:-$HOME/.gradle}/native"
    rpath="${ncurses}/lib:${stdenv.cc.cc.lib}/lib"

    if [ ! -d "$nativeDir" ]; then
      echo "No native cache at $nativeDir, nothing to fix." >&2
      exit 0
    fi

    patched=0
    while IFS= read -r -d "" so; do
      if [ -z "$(patchelf --print-rpath "$so")" ]; then
        echo "Patching $so"
        patchelf --set-rpath "$rpath" "$so"
        patched=$((patched + 1))
      fi
    done < <(find "$nativeDir" -name 'libnative-platform-curses.so' -type f -print0)

    echo "Patched $patched libraries. Rich console should work again."
  '';
}
