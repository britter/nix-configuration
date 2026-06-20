_: {
  imports = [
    ./terminal
  ];

  my.home = {
    terminal = {
      enable = true;
    };
  };

  programs.nixvim = {
    plugins = {
      none-ls.sources.formatting.google_java_format.enable = true;
    };
  };
}
