{ ... }:
{
  imports = [
    ./desktop
    ./java
    ./terminal
  ];
  config = {
    my.home = {
      desktop.enable = true;
      java = {
        enable = true;
        version = 25;
        additionalVersions = [
          8
          11
          17
          21
        ];
      };
      terminal.enable = true;
    };
    catppuccin = {
      enable = true;
      flavor = "macchiato";
    };
  };
}
