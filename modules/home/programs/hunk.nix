{ inputs, ... }:
{
  flake.modules.homeManager.hunk =
    { config, lib, ... }:
    let
      cfg = config.programs.hunk;
    in
    {
      imports = [ inputs.hunk.homeManagerModules.hunk ];

      options.programs.hunk.enableOpenCodeIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to link the hunk-review skill under ~/.config/opencode/skills.";
      };

      config = lib.mkIf (cfg.enable && cfg.enableOpenCodeIntegration) {
        xdg.configFile."opencode/skills/hunk-review".source = "${cfg.package}/skills/hunk-review";
      };
    };
}
