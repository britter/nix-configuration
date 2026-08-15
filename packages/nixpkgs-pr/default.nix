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
    rev = "c9164fc391380ca0d259c5f9474b3a4e6ac16c08";
    hash = "sha256-eCJLTtiFDB+t54PSd3d7mMwPgExkZMTskwqiFhA93rc=";
  };

  cargoHash = "sha256-0q95j+sO7pAgV4XPO2UNS6HnOIW5wVOxCkCbVnyAK18=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
