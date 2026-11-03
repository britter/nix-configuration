_: {
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      programs.steam.enable = true;
      # run games in an optimized micro compositor
      programs.steam.gamescopeSession.enable = true;

      nixpkgs.config.allowUnfreePackages = [
        "steam"
        "steam-original"
        "steam-run"
        "steam-unwrapped"
      ];

      # lutris' FHS environment still ships gtk2, which nixpkgs marks as
      # broken since https://github.com/NixOS/nixpkgs/issues/410814.
      # Evaluating a system that imports this module (e.g. the mandb service
      # walking environment.systemPackages) refuses to evaluate because of
      # it, so downgrade the hardcoded eval error to a warning until lutris
      # drops gtk2 upstream. Upstream tracks this as an open lutris task in
      # 410814; remove this override once that lands.
      nixpkgs.config.problems.handlers."gtk+".broken = "warn";

      # performance stats overlay
      environment.systemPackages = [
        pkgs.mangohud
        pkgs.lutris
      ];

      # requests OS optimizations while gaming
      programs.gamemode.enable = true;
    };
}
