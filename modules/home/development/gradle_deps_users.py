"""List the attribute names of all gradle consumers (packages using
gradle*.fetchDeps), one per line, for piping into nixpkgs-review(-remote).

    nix run nixpkgs#python3 -- gradle_deps_users.py \
      | sed 's/^/-p /' | xargs -r nixpkgs-review-remote rev HEAD
"""
import subprocess

# path (as printed by rg) -> correct top-level attribute path
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

files = subprocess.run(
    ["rg", "-l", r"mitmCache\s*=\s*gradle(?:_\d+)?\.fetchDeps", "pkgs/"],
    capture_output=True, text=True, check=True).stdout.split()

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
