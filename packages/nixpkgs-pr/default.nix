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
    rev = "b4ac2d7b400ad6fcec2c4f5157544437ecee1c48";
    hash = "sha256-VjRWJ6cmFRyZxNRc7ZPmGHekieEqfNLIdZKyU1OLo30=";
  };

  cargoHash = "sha256-yhzIC2T4zv/lPCvF1Tx2p4D+AoWKT+B8hY+6E7V5rjw=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
