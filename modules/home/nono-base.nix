_: {
  flake.modules.homeManager.nono-base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # `meta.name` is the only field nono requires; every other key has a
      # serde default in the parser, so profiles only carry what they set.
      renderProfile = name: value: lib.recursiveUpdate { meta.name = name; } value;

      cfg = config.programs.nono;
      jsonFormat = pkgs.formats.json { };
    in
    {
      options.programs.nono = {
        enable = lib.mkEnableOption "nono sandbox";

        package = lib.mkPackageOption pkgs "nono" { };

        profiles = lib.mkOption {
          description = ''
            nono sandbox profiles, rendered to ~/.config/nono/profiles/<name>.json.
            The attribute name is the profile name and becomes `meta.name`;
            every other key is optional and defaults inside nono's parser.
          '';
          type = lib.types.attrsOf jsonFormat.type;
          default = { };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        xdg.configFile = lib.mapAttrs' (name: value: {
          name = "nono/profiles/${name}.json";
          value.source = jsonFormat.generate "nono-profile-${name}" (renderProfile name value);
        }) cfg.profiles;
      };
    };
}
