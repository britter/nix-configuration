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
