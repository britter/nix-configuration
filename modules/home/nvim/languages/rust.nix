_: {
  flake.modules.homeManager.nvim =
    { config, ... }:
    {
      programs.nixvim.plugins.lsp.servers.rust_analyzer = {
        enable = config.programs.cargo.enable;
        installCargo = true;
        installRustc = true;
        installRustfmt = true;
      };
    };
}
