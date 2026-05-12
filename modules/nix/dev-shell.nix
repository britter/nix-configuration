_: {
  perSystem =
    { pkgs, self', ... }:
    {
      devShells.default = pkgs.mkShell {
        inherit (self'.checks.pre-commit-check) shellHook;
        buildInputs = self'.checks.pre-commit-check.enabledPackages;
        packages = with pkgs; [
          sops
          minio-client
        ];
      };
    };
}
