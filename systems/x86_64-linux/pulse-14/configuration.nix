{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-facter-modules.nixosModules.facter
    ../../../modules/nixos
  ];

  facter.reportPath = ./facter.json;
  networking.useDHCP = true;

  my = {
    host = {
      role = "desktop";
      profiles = ["private"];
    };
    user.signingKey = "394546A47BB40E12";
    modules = {
      disko = {
        enable = true;
        bootDisk = "/dev/nvme0n1";
        swapSize = "32GB";
      };
    };
  };

  services.printing.enable = true;
  services.xserver.videoDrivers = ["amdgpu"];

  # Workaround for getting automatic downloads of protoc via ptotobuf-gradle-plugin working
  # Source: https://discourse.nixos.org/t/protobuf-cant-be-run/13568/8
  systemd.tmpfiles.rules = [
    "L+ /lib64/ld-linux-x86-64.so.2 - - - - ${pkgs.glibc}/lib64/ld-linux-x86-64.so.2"
  ];

  virtualisation.docker.enable = true;
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
