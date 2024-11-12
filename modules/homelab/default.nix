{lib, ...}: {
  options.my.homelab = {
    fritz-box = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.1";
      };
    };
    proxmox = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.100";
      };
    };
    directions = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.105";
      };
    };
    srv-prod-1 = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.211";
      };
    };
    srv-prod-2 = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.212";
      };
    };
    srv-test-1 = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.221";
      };
    };
    srv-test-2 = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.222";
      };
    };
    srv-eval-1 = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.231";
      };
    };
  };
}
