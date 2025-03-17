{...}: {
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
        version = 21;
        additionalVersions = [8 11 17];
      };
      terminal.enable = true;
    };
    catppuccin = {
      enable = true;
      flavor = "latte";
    };
  };
}
