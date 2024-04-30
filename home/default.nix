{
  config,
  pkgs,
  osConfig,
  ...
}: let
  enableDesktop = pkgs.stdenv.isLinux && osConfig.my.host.role == "desktop";
  isServer = osConfig.my.host.role == "server";
in {
  imports = [
    ./desktop
    ./java
    ./profiles
    ./terminal
  ];
  config = {
    my.home = {
      # enabled on linux desktops only
      desktop.enable = enableDesktop;

      # enabled everywhere but servers
      java.enable = !isServer;

      # enabled on all machines
      terminal.enable = true;
    };
  };
}
