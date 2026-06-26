_: {
  flake.modules.nixos.beszel-agent = _: {
    services.beszel.agent = {
      enable = true;
      openFirewall = true;
      environment = {
        PORT = "45876";
        # Bezel Hub's SSH public key, which is stored in /var/lib/beszel-hub/id_ed25519.pub.
        # For Beszel on srv-prod-1, the value is stored in modules/hosts/srv-prod-1/secrets.yaml
        KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDM4/5m4XKP1a+BT7nVqmo4NaHJIk26rS+NbemzQw6y5 bene@framework-13";
      };
    };
  };
}
