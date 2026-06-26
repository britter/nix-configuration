{ config, ... }:
{
  flake.modules.nixos.test-vm = {
    imports = with config.flake.modules.nixos; [
      system-base
      romm
    ];

    networking.hostName = "test-vm";
    networking.firewall.allowedTCPPorts = [ 80 ];

    # Placeholders so `nix flake check` can evaluate
    # nixosConfigurations.test-vm.config.system.build.toplevel. The
    # qemu-vm module that gets pulled in for `.config.system.build.vm`
    # supplies the real values.
    boot.loader.systemd-boot.enable = true;
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    users.users.root.initialPassword = "root";

    environment.etc."romm-test.env".text = ''
      ROMM_AUTH_SECRET_KEY=test-vm-secret-not-for-production
    '';

    services.romm = {
      enable = true;
      environmentFiles = [ "/etc/romm-test.env" ];
      nginx = {
        enable = true;
        hostName = "localhost";
      };
    };

    # VM-only knobs picked up by nixos-rebuild build-vm.
    virtualisation.vmVariant = {
      virtualisation = {
        memorySize = 2048;
        cores = 2;
        diskSize = 8192;
        graphics = false;
        forwardPorts = [
          {
            from = "host";
            host.port = 8080;
            guest.port = 80;
          }
        ];
      };
      services.getty.autologinUser = "root";
    };

    system.stateVersion = "26.05";
  };
}
