{
  config,
  pkgs,
  osConfig,
  ...
}: let
  enableDesktop = pkgs.stdenv.isLinux && osConfig.my.host.role == "desktop";
in {
  imports = [
    ./desktop
    ./terminal
  ];
  config = {
    my.home = {
      desktop.enable = enableDesktop;
      terminal.enable = true;
    };
  };
}
