-- See https://github.com/dwf/dotfiles/blob/6913670108bc9dcee5ca5264e17d162c57858967/neovim/snippets/nix.lua
-- for more inspiration
return {
    s(
        { trig = "module", desc = "Module template with options" },
        fmt(
            [[
              {{
                config,
                lib,
                pkgs,
                ...
              }}: let
                cfg = config.{};
              in {{
                options.{} = {{
                  enable = lib.mkEnableOption "{}";
                }};

                config = lib.mkIf cfg.enable {{
                  {}
                }};
              }}
            ]],
            {
                i(1),
                rep(1),
                f(function()
                    return vim.fn.expand("%:t:r")
                end),
                i(0),
            }
        )
    ),
}, {}
