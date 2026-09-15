_: {
  flake.modules.homeManager.nvim = {
    # The colorscheme itself comes from stylix's nixvim target. base16-nvim
    # instead of the default mini.base16 because it ships highlight groups for
    # treesitter, the LSP and the plugins configured in this directory.
    stylix.targets.nixvim.plugin = "base16-nvim";
  };
}
