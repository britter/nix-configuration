{
  pkgs,
  config,
  lib,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
  projectsType = lib.types.submodule (
    { name, ... }:
    {
      freeformType = yamlFormat.type;
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
      };
    }
  );
in
{
  options.programs.tmux.tmuxinator.projects = lib.mkOption {
    type = lib.types.attrsOf projectsType;
    default = { };
  };

  config = lib.mkIf (config.programs.tmux.enable && config.programs.tmux.tmuxinator.enable) {
    home.file = lib.mapAttrs' (
      _k: v:
      lib.nameValuePair ".config/tmuxinator/${v.name}.yaml" {
        source = yamlFormat.generate "${v.name}.yaml" v;
      }
    ) config.programs.tmux.tmuxinator.projects;
  };
}
