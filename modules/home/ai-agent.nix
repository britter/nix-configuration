{
  flake.modules.homeManager.ai-agent =
    { pkgs, ... }:
    let
      nono-packs = pkgs.fetchFromGitHub {
        owner = "nolabs-ai";
        repo = "nono-packs";
        rev = "6e54577b32a28cc9899e2bea6673bbe9c3ae1953";
        hash = "sha256-+vaB+nmjYW9zYdHrGlgvV9m5GiRfQb3YO/S416YnWdM=";
      };
      # Zero-dependency opencode plugin; resolves its hooks/ and skills/
      # relative to the .mjs, so we can run it straight from the pinned source.
      ponytail = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "v4.8.3";
        hash = "sha256-4ZT89GA5xnomNBIzY8Kh1yYP0AC9SeVhv406DEKpE3A=";
      };
    in
    {
      programs.nono = {
        enable = true;
        packs."nolabs-ai/opencode".src = "${nono-packs}/opencode";
      };

      programs.opencode = {
        enable = true;
        settings = {
          plugin = [ "${ponytail}/.opencode/plugins/ponytail.mjs" ];

          # A primary agent (cycle to it with Tab) that asks before mutations,
          # like Claude Code's default. The built-in build agent is left as-is.
          agent.careful = {
            mode = "primary";
            permission = {
              edit = "ask";
              bash = "ask";
              webfetch = "ask";
              external_directory = "ask";
            };
          };
        };
      };
    };
}
