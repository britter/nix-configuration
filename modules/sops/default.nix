{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.modules.sops;
  defaultSopsPath = "${toString inputs.self}/systems/${config.my.host.system}/${config.my.host.name}/secrets.yaml";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options.my.modules.sops = {
    enable = lib.mkEnableOption "sops";
  };

  config = lib.mkIf cfg.enable {
    sops.defaultSopsFile = lib.mkIf (builtins.pathExists defaultSopsPath) defaultSopsPath;
    # This will automatically import SSH keys as age keys
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
