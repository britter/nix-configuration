_: {
  flake.modules.nixos.beszel-agent = { config, ... }: {
    sops.secrets."beszel/token" = {
      owner = "beszel-agent";
    };
    services.beszel.agent = {
      enable = true;
      openFirewall = true;
      environment = {
        HUB_URL = "https://beszel.ritter.family";
        PORT = "45876";
        # Beszel Hub's SSH public key, installed as /var/lib/beszel-hub/id_ed25519.pub
        # on the hub host (directions). The value is stored in modules/hosts/directions/secrets.yaml
        KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDM4/5m4XKP1a+BT7nVqmo4NaHJIk26rS+NbemzQw6y5 bene@framework-13";
        TOKEN_FILE = config.sops.secrets."beszel/token".path;
      };
    };
  };
}
