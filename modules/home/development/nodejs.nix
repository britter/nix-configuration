_: {
  flake.modules.homeManager.nodejs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      npmGlobalDir = "${config.home.homeDirectory}/.npm-global";
    in
    {
      home.packages = with pkgs; [
        nodejs
      ];
      systemd.user.tmpfiles.rules = [
        "d ${npmGlobalDir} 0700 ${config.home.username} - -"
      ];
      home.sessionPath = [
        "${npmGlobalDir}/bin"
      ];
      # Run npm config set during activation to store prefix in ~/.npmrc
      home.activation.setNpmPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.nodejs}/bin/npm config set prefix ${npmGlobalDir}
      '';
    };
}
