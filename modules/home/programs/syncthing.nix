_: {
  flake.modules.homeManager.syncthing = {
    services.syncthing = {
      enable = true;
      tray = {
        enable = true;
        command = "syncthingtray --wait";
      };
    };
  };
}
