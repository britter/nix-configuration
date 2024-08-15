{lib, ...}: {
  options.my.homelab = {
    cyberoffice = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.200";
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
    watchtower = {
      ip = lib.mkOption {
        type = lib.types.str;
        default = "192.168.178.210";
      };
    };
  };
}
