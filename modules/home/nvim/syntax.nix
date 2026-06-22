_: {
  flake.modules.homeManager.nvim = {
    programs.nixvim.plugins.treesitter = {
      enable = true;
      settings = {
        indent.enable = true;
        highlight.enable = true;
      };
    };
  };
}
