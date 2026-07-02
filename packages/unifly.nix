{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  llvmPackages,
  installShellFiles,
  dbus,
  versionCheckHook,
  ...
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "unifly";
  version = "0.9.2";

  src = fetchFromGitHub {
    owner = "hyperb1iss";
    repo = "unifly";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Hw/zm9OjBcAI0H2vvwnAj4tjF0E+d6RHpWIexhPBuy8=";
  };

  nativeBuildInputs = [
    pkg-config
    llvmPackages.bintools
    installShellFiles
  ];

  buildInputs = [ dbus ];

  cargoHash = "sha256-4nLfMzlN5KQK3JvmoHbktI/tyc3aaI78Oa5RtQN4xLo=";

  doCheck = false;
  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  postInstall = ''
    installShellCompletion --cmd unifly \
      --bash <($out/bin/unifly completions bash) \
      --fish <($out/bin/unifly completions fish) \
      --zsh <($out/bin/unifly completions zsh)
  '';

  meta = {
    description = "";
    homepage = "";
    license = lib.licenses.apsl20;
    maintainers = with lib.maintainers; [ britter ];
  };
})
