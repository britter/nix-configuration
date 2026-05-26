{ inputs, ... }:
{
  flake.factory.sops =
    { secretsFile }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      sops.defaultSopsFile = secretsFile;
    };
}
