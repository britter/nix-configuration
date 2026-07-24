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
    rev = "269924503e4305e530837b9c7e6f5ed75a93c7d0";
    hash = "sha256-2zErDwhyK9lubcwmF36w4ozYCb6u92uNbB+89NmPBsA=";
  };

  cargoHash = "sha256-yhzIC2T4zv/lPCvF1Tx2p4D+AoWKT+B8hY+6E7V5rjw=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
