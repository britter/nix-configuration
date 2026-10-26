{
  fetchFromGitHub,
  python3Packages,
}:
python3Packages.buildPythonPackage (_finalAttrs: {
  pname = "skills-ref";
  version = "0.1.0";

  # The Agent Skills reference validator, from the agentskills standard's
  # own repository. The skills-ref subdirectory is one Python project in a
  # monorepo.
  src = fetchFromGitHub {
    owner = "agentskills";
    repo = "agentskills";
    rev = "69ef37e9424c0a7ea9dd2293b559e43ec8176379";
    hash = "sha256-9coLvkonrdbkIAf6DVvCH6rfjPuyaCA/eb1RsFBMiSg=";
  };
  sourceRoot = "source/skills-ref";

  pyproject = true;
  build-system = [ python3Packages.hatchling ];
  dependencies = with python3Packages; [
    click
    strictyaml
  ];

  # The upstream README marks the tool as a reference implementation for
  # demonstration purposes; running its pytest suite is not worth the
  # dependency weight for a validation check.
  doCheck = false;
})
