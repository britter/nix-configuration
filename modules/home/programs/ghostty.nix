_: {
  flake.modules.homeManager.ghostty = {
    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        confirm-close-surface = false;
        font-family = "FiraCode Nerd Font Mono";
        font-feature = "-calt";
      };
    };
  };
}
