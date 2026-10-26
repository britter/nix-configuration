{
  fetchFromGitHub,
  python3,
  writeShellScriptBin,
}:
# The Simplified Technical English linter from the asd-ste100 skill
# (https://github.com/danyuchn/asd-ste100-skill), packaged as a standalone
# command for build-time prose checks. The linter is stdlib-only Python.
# This pins the same upstream revision as the asd-ste100 skill source in
# modules/home/ai/skills.nix — bump the two together.
writeShellScriptBin "ste-lint" ''
  exec ${python3}/bin/python3 ${
    fetchFromGitHub {
      owner = "danyuchn";
      repo = "asd-ste100-skill";
      rev = "8da6b6340aa22faf46fd07db8efbdea010cd38d9";
      hash = "sha256-s1SVG0ecMcrej45kyQ1s78lGTzscv3CV3M5UGsZwckE=";
    }
  }/scripts/ste-lint.py "$@"
''
