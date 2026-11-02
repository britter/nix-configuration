{
  rustPlatform,
  fetchFromCodeberg,
  versionCheckHook,
}:
rustPlatform.buildRustPackage (_finalAttrs: {
  __structuredAttrs = true;

  pname = "nixpkgs-pr";
  version = "0-unstable-2026-11-02";

  src = fetchFromCodeberg {
    owner = "britter";
    repo = "nixpkgs-pr";
    rev = "9fd529219522a6648d88f701ade4f4e42194721e";
    hash = "sha256-NHMfjvDAjIxWkLpM6ezLlaLm7e82ojyHGFJ59/ErUs4=";
  };

  cargoHash = "sha256-w6aLQ/5ikMgSFOXwFgevwDNw3IzYdLEOes4pK6Aet3s=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
