{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    helix
    git
  ];

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce ["multi-user.target"];
  users.users.root.openssh.authorizedKeys.keyFiles = [./bene_rsa.pub];
}
