{pkgs, ...}: {
  imports = [
    ./desktop
    ./java
    ./profiles
    ./terminal
  ];
  config = {
    my.home = {
      desktop.enable = pkgs.stdenv.isLinux;

      java.enable = true;
      terminal.enable = true;
    };
    catppuccin = {
      enable = true;
      flavor = "macchiato";
    };
  };
}
