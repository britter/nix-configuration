{ inputs, ... }:
{
  imports = [ inputs.pre-commit-hooks.flakeModule ];

  perSystem =
    { config, ... }:
    {
      # Run the treefmt wrapper instead of individual hooks, so treefmt.nix
      # stays the only place formatters are configured.
      pre-commit.settings.hooks.treefmt = {
        enable = true;
        package = config.treefmt.build.wrapper;
      };
    };
}
