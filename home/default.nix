{...}: {
  imports = [
    ./desktop
    ./java
    ./terminal
  ];
  config = {
    my.home = {
      desktop.enable = true;
      java.enable = true;
      terminal.enable = true;
    };
    catppuccin = {
      enable = true;
      flavor = "macchiato";
    };
  };
}
