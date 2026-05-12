{ inputs, ... }:
{
  imports = [ inputs.pre-commit-hooks.flakeModule ];
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        inherit (config.pre-commit) shellHook;
        buildInputs = config.pre-commit.settings.enabledPackages;
        packages = with pkgs; [
          sops
          minio-client
        ];
      };
    };
}
