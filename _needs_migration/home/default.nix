{ ... }:
{
  imports = [
    ./desktop
    ./java
    ./rust
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
      rust.enable = true;
      terminal.enable = true;
    };
    catppuccin = {
      enable = true;
      flavor = "macchiato";
    };
  };
}
