{
  flake.modules.homeManager.nono =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.nono;
      jsonFormat = pkgs.formats.json { };

      # nono resolves `--profile <namespace>/<name>` from
      # packages/<namespace>/<name>/profiles/<name>.json, which is the pack's
      # policy.json renamed. Runtime needs no signature/lockfile, so we just lay
      # the fetched pack out on disk with that one rename.
      mkPack =
        ref: pack:
        let
          profileName = lib.last (lib.splitString "/" ref);
        in
        pkgs.runCommand "nono-pack-${lib.replaceStrings [ "/" ] [ "-" ] ref}" { } ''
          mkdir -p $out/profiles
          cp -r ${pack.src}/. $out/
          cp ${pack.src}/${pack.profileFile} $out/profiles/${profileName}.json
        '';
    in
    {
      options.programs.nono = {
        enable = lib.mkEnableOption "nono capability-based sandbox";

        package = lib.mkPackageOption pkgs "nono" { };

        profiles = lib.mkOption {
          type = lib.types.attrsOf jsonFormat.type;
          default = { };
          example = lib.literalExpression ''
            {
              my-agent = {
                extends = "default";
                groups.include = [ "deny_credentials" ];
                workdir.access = "readwrite";
              };
            }
          '';
          description = ''
            User profiles rendered to {file}`$XDG_CONFIG_HOME/nono/profiles/<name>.json`
            and referenced as `nono run --profile <name>`.
          '';
        };

        packs = lib.mkOption {
          default = { };
          description = ''
            Registry packs placed on disk declaratively instead of via `nono pull`.
            The attribute name is the pack reference (`<namespace>/<name>`) used with
            `nono run --profile <namespace>/<name>`.
          '';
          example = lib.literalExpression ''
            {
              "nolabs-ai/opencode".src = "''${pkgs.fetchFromGitHub {
                owner = "nolabs-ai";
                repo = "nono-packs";
                rev = "<commit>";
                hash = "<sha256>";
              }}/opencode";
            }
          '';
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                src = lib.mkOption {
                  type = lib.types.path;
                  description = "Pack directory containing the profile file (e.g. a fetchFromGitHub subpath).";
                };
                profileFile = lib.mkOption {
                  type = lib.types.str;
                  default = "policy.json";
                  description = "Profile file within {option}`src` to install as the pack profile.";
                };
              };
            }
          );
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        xdg.configFile =
          lib.mapAttrs' (
            name: value:
            lib.nameValuePair "nono/profiles/${name}.json" {
              source = jsonFormat.generate "nono-profile-${name}.json" value;
            }
          ) cfg.profiles
          // lib.mapAttrs' (
            ref: pack: lib.nameValuePair "nono/packages/${ref}" { source = mkPack ref pack; }
          ) cfg.packs;
      };
    };
}
