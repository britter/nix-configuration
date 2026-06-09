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

      # performance stats overlay
      environment.systemPackages = [ pkgs.mangohud ];

      # requests OS optimizations while gaming
      programs.gamemode.enable = true;
    };
}
