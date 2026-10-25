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
    rev = "fde852b0832e337043a5f084bef9e579fd358e04";
    hash = "sha256-5N/uXXFqltad0ajG9ktxaX5cJR6Q1rBdWRkO3iLSZQ8=";
  };

  cargoHash = "sha256-gpGsMGwtno949ma6sBsVvs8d3ZIEIqvLISWnV54qJQU=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
