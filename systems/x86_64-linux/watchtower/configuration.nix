{config, ...}: {
  imports = [
    ../../../modules/nixos
  ];

  my = {
    host = {
      name = "watchtower";
      system = "x86_64-linux";
      ip = "192.168.178.210";
      role = "server";
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

  networking = {
    firewall = {
      allowedTCPPorts = [80 443 config.services.grafana.settings.server.http_port];
    };
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
