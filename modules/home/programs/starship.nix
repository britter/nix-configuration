_: {
  flake.modules.homeManager.starship =
    { pkgs, ... }:
    let
      # Prints the PR number for the checked-out branch, cached so the prompt
      # never blocks on a network call. Reads the cache instantly and refreshes
      # in the background when missing or stale (>1 day). The empty "no PR"
      # result is cached too, so branches without a PR (main, fresh branches)
      # hit the API at most once a day instead of every prompt.
      # Force a refresh: rm -rf "$XDG_RUNTIME_DIR/starship-gh-pr"
      starship-gh-pr = pkgs.writeShellApplication {
        name = "starship-gh-pr";
        runtimeInputs = with pkgs; [
          gh
          git
          coreutils
          findutils
        ];
        text = ''
          dir="''${XDG_RUNTIME_DIR:-/tmp}/starship-gh-pr"
          top=$(git rev-parse --show-toplevel 2>/dev/null) || exit 1
          branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || exit 1
          cache="$dir/$(basename "$top")_''${branch//\//_}"
          mkdir -p "$dir"

          # Missing or stale → kick a background fetch; touch first to debounce
          # so a second prompt during the fetch doesn't spawn another one.
          if [ ! -e "$cache" ] || [ -n "$(find "$cache" -mmin +1440 2>/dev/null)" ]; then
            touch "$cache"
            { gh pr view --json number -q .number 2>/dev/null >"$cache"; } &
          fi

          pr=$(cat "$cache" 2>/dev/null)
          [ -n "$pr" ] || exit 1
          printf '%s' "$pr"
        '';
      };
    in
    {
      programs.starship = {
        enable = true; # prompt framework
        # Same script for `when` (always runs → drives the refresh, hides the
        # module when there's no PR) and `command` (prints the number).
        settings.custom.pr = {
          command = "${starship-gh-pr}/bin/starship-gh-pr";
          when = "${starship-gh-pr}/bin/starship-gh-pr";
          require_repo = true;
          format = "on [ #$output](bold purple) ";
        };
      };
    };
}
