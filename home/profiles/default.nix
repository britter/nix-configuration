{
  config,
  osConfig,
  ...
}: let
  profiles = osConfig.my.host.profiles;
in {
  imports = [
    ./private.nix
    ./work.nix
  ];

  config = {
    my.home.profiles = {
      private.enable = builtins.elem "private" profiles;
      work.enable = builtins.elem "work" profiles;
    };
  };
}
