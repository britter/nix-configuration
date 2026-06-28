_: {
  flake.modules.generic.home-lab =
    { lib, ... }:
    {
      options.home-lab = lib.mkOption {
        type = lib.types.attrs;
        description = "Network topology of the home lab.";
      };

      config.home-lab = {
        hosts = {
          srv-prod-1 = {
            ip = "192.168.30.11";
            dns = "srv-prod-1.ritter.family";
            vm = true;
          };
          srv-prod-2 = {
            ip = "192.168.30.12";
            dns = "srv-prod-2.ritter.family";
            vm = true;
          };
          srv-prod-3 = {
            ip = "192.168.30.13";
            dns = "srv-prod-3.ritter.family";
            vm = true;
          };
          srv-prod-4 = {
            ip = "192.168.30.14";
            dns = "srv-prod-4.ritter.family";
            vm = true;
          };
          srv-prod-5 = {
            ip = "192.168.30.15";
            dns = "srv-prod-5.ritter.family";
            vm = true;
          };
          srv-prod-6 = {
            ip = "192.168.30.16";
            dns = "srv-prod-6.ritter.family";
            vm = true;
          };
          srv-offsite-1 = {
            dns = "srv-offsite-1.ritter.family";
            vm = false;
          };
          directions = {
            ip = "192.168.5.6";
            dns = "directions.ritter.family";
            vm = false;
          };
          home-assistant = {
            ip = "192.168.20.234";
            dns = "homeassistant.ritter.family";
            vm = false;
          };
        };
        hypervisors = {
          pve = {
            ip = "192.168.10.10";
            dns = "pve.ritter.family";
            vm = false;
          };
        };
        devices = {
          fritz-box = {
            ip = "192.168.178.1";
            dns = "fritz-box.ritter.family";
            vm = false;
          };
          jetkvm = {
            ip = "100.96.211.6";
            dns = "jetkvm.ritter.family";
            vm = false;
          };
        };
      };
    };
}
