{lib, ...}: {
  options.my.homelab = {
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
    srv-prod-2 = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.212";
      };
    };
    watchtower = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.210";
      };
    };
  };
}
