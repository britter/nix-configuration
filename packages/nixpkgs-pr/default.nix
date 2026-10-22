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
    rev = "70ddeb360e38b6f2967d922ae880f576ff612a0c";
    hash = "sha256-1pNB50liQSuva4PsbzPEPXiPSNEHs1NF/TnM8H6iswc=";
  };

  cargoHash = "sha256-Jhy0nldP778ROAR1Gz7kuHWN5cZXm+S0nbl0B+p/lOE=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
