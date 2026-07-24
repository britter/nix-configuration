{
  rustPlatform,
  fetchFromCodeberg,
  versionCheckHook,
}:
rustPlatform.buildRustPackage (_finalAttrs: {
  __structuredAttrs = true;

  pname = "clipmd";
  version = "0.1.0";

  src = fetchFromCodeberg {
    owner = "britter";
    repo = "clipmd";
    rev = "ef63959d7af4949189c96bf4c358957d2dd6ffb3";
    hash = "sha256-xaK2ih+ZSoZcJdZlXJEzbBn9t4krta0Nn+j/PfdARsU=";
  };

  cargoHash = "sha256-ZGVJj8EGnD0dWSIEdEMpDDrZrPIZCL2nYvYG6QjBdWk=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
