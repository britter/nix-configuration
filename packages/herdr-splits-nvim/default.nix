{
  vimUtils,
  fetchFromGitHub,
  lib,
}:
# Serves both halves of the integration: `lua/` is the Neovim plugin, while
# `herdr-plugin.toml` + `scripts/` are what herdr registers as a plugin.
vimUtils.buildVimPlugin {
  pname = "herdr-splits-nvim";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "lmilojevicc";
    repo = "herdr-splits.nvim";
    tag = "v0.5.2";
    hash = "sha256-tiYFNZh0z8aLVzf56+Z/xo0lFvbztReG9oiXy19dv6s=";
  };

  meta = {
    description = "Seamless navigation between Neovim splits and herdr panes";
    homepage = "https://github.com/lmilojevicc/herdr-splits.nvim";
    license = lib.licenses.mit;
  };
}
