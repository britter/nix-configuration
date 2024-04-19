{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./terminal
  ];
  config = {
    my.home = {
      terminal.enable = true;
    };
  };
}
