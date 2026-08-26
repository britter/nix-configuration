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
    rev = "4677cabf029fe552e9af3f91b6a91b3c64db8b14";
    hash = "sha256-PqIMD1rY8n/o5AD0F11xV8FFUHYexAw25Po0LMlC2YQ=";
  };

  cargoHash = "sha256-Jhy0nldP778ROAR1Gz7kuHWN5cZXm+S0nbl0B+p/lOE=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
})
