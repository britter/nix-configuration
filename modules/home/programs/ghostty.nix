_: {
  flake.modules.homeManager.ghostty = {
    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        confirm-close-surface = false;
        font-feature = "-calt";
      };
    };
  };
}
