_: {
  # nix-ld provides an FHS-style loader so unpatched dynamic binaries can run.
  flake.modules.nixos.testlens-support = {
    # required to run the protoc compiler that is wrapped into the protobuf Gradle plugin
    programs.nix-ld.enable = true;
    home-manager.sharedModules = [
      {
        programs.nono.profiles."testlens" = {
          extends = [ "opencode" ];
          meta = {
            version = "1.0.0";
            description = "Additions for working on testlens projects";
          };
          filesystem.allow = [
            "~/github/testlens-app"
          ];
        };
      }
    ];
  };
}
