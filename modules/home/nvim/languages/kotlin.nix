_: {
  flake.modules.homeManager.nvim =
    { pkgs, ... }:
    {
      programs.nixvim.plugins.lsp.servers.kotlin_lsp = {
        enable = true;
        package = pkgs.kotlin-lsp;
      };
    };
}
