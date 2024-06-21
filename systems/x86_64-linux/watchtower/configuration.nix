{
  config,
  inputs,
  ...
}: {
  imports = [
    ../../../modules/nixos
    inputs.comin.nixosModules.comin
  ];

  my = {
    host = {
      name = "watchtower";
      system = "x86_64-linux";
      role = "server";
    };
    # TODO make the user module optional. Servers don't need a dedicated user
    user = {
      # default name baked into the ISO image
      name = "nixos";
      # TODO make this optional. Signing is not required on servers.
      signingKey = "394546A47BB40E12";
    };
    modules = {
      disko = {
        enable = true;
        disk = "/dev/sda";
      };
    };
  };

  # TODO extract into a VM module
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
  services.qemuGuest.enable = true;

  # TODO extract this into a module. Make IP address part of my.host
  networking = {
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.178.210";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.178.1";
    nameservers = ["192.168.178.105"];
    firewall = {
      allowedTCPPorts = [80 443 config.services.grafana.settings.server.http_port];
    };
  };

  # TODO extract this into a server module
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/britter/nix-configuration.git";
      }
    ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."grafana.ritter.family" = {
      serverAliases = ["grafana.*"];
      locations."/" = {
        proxyWebsockets = true;
        recommendedProxySettings = true;
        proxyPass = "http://localhost:3000";
      };
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = "grafana.ritter.family";
      };
    };
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            uid = "Prometheus1";
            # TODO reference prometheus service configuration
            url = "http://localhost:9090";
          }
        ];
      };
    };
  };

  # See https://wiki.nixos.org/wiki/Prometheus
  services.prometheus = {
    enable = true;
    # keep data for 90 days
    extraFlags = ["--storage.tsdb.retention.time=90d"];
    exporters.node = {
      enable = true;
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["localhost:9100"];
          }
        ];
      }
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
