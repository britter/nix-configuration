{ inputs, config, ... }:
let
  inherit (config.flake.lib) relativePath;
in
{
  imports = [ inputs.pre-commit-hooks.flakeModule ];
  perSystem =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      devShells.default =
        let
          setup-host = pkgs.writeShellApplication {
            name = "setup-host";
            runtimeInputs = [
              pkgs.gum
              pkgs.nixos-anywhere
              pkgs.sops
              pkgs.openssh
              pkgs.jq
              pkgs.git
            ];
            runtimeEnv = {
              CONFIGURATIONS = lib.pipe inputs.self.nixosConfigurations [
                lib.attrNames
                (lib.filter (lib.hasPrefix "srv"))
                (lib.concatStringsSep " ")
              ];
              HOST_KEYS_FILE = relativePath ./host-keys.yaml;
            };
            text = builtins.readFile ./setup-host.sh;
          };
        in
        pkgs.mkShell {
          inherit (config.pre-commit) shellHook;
          buildInputs = config.pre-commit.settings.enabledPackages;
          packages = with pkgs; [
            minio-client
            setup-host
            sops
          ];
        };
    };
}
