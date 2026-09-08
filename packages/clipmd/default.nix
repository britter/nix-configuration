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
    rev = "eff338f513034b20dc73b7dabec964bec3ae99ff";
    hash = "sha256-9auwdAVaKHwmkl1MhxtN3l7C9OkxMS+LICVWtzLBZNs=";
  };

  cargoHash = "sha256-Wn5B/8P6H37+SEwPGZUMaiX5fQFPq71A8+10kwWfkoc=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
