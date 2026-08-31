{
  rustPlatform,
  fetchFromCodeberg,
  versionCheckHook,
}:
rustPlatform.buildRustPackage (_finalAttrs: {
  __structuredAttrs = true;

  pname = "nixpkgs-pr";
  version = "0.1.0";

  src = fetchFromCodeberg {
    owner = "britter";
    repo = "nixpkgs-pr";
    rev = "7ec52918f5120185e20c57f8c1130f41a557e802";
    hash = "sha256-yVQBbYbNcHO6l5UmNtIqAjDyd2BHip8yI8EqCAc1Z9Q=";
  };

  cargoHash = "sha256-Jhy0nldP778ROAR1Gz7kuHWN5cZXm+S0nbl0B+p/lOE=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
