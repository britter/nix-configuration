{
  pkgs,
  inputs,
  home-lab,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    neovim
    git
  ];

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keyFiles = [ ./id_ed25519.pub ];

  networking = {
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.178.199";
        prefixLength = 24;
      }
    ];
    defaultGateway = home-lab.devices.fritz-box.ip;
    nameservers = [ home-lab.hosts.directions.ip ];
  };
}
