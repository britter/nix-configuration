_: {
  flake.modules.nixos.scanning =
    { config, pkgs, ... }:
    let
      usernames = builtins.attrNames config.home-manager.users;
    in
    {
      hardware.sane.enable = true;

      users.users = builtins.listToAttrs (
        map (u: {
          name = u;
          value.extraGroups = [ "scanner" ];
        }) usernames
      );

      home-manager.sharedModules = [ { home.packages = [ pkgs.simple-scan ]; } ];
    };
}
