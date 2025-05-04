{
  pkgs,
  config,
  lib,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
{
  options.programs.tmux.tmuxinator.projects = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule { freeformType = yamlFormat.type; });
    default = [ ];
  };

  config = lib.mkIf (config.programs.tmux.enable && config.programs.tmux.tmuxinator.enable) {
    home.file = lib.mkMerge (
      lib.map (p: {
        ".config/tmuxinator/${p.name}.yaml".source = yamlFormat.generate "${p.name}.yaml" p;
      }) config.programs.tmux.tmuxinator.projects
    );
  };
}
