{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.my.modules.sops;
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options.my.modules.sops = {
    enable = lib.mkEnableOption "sops";
    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.defaultSopsFile = cfg.sopsFile;
    # This will automatically import SSH keys as age keys
    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
}
