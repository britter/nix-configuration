{ inputs, ... }:
{
  # Migration scaffold.
  #
  # While the legacy NixOS modules under _needs_migration still exist,
  # framework-13 pulls them in unconditionally here. The bridge
  # imports modules (vaultwarden, nextcloud, minio, …) whose config
  # blocks reference sops.X under mkIf cfg.enable. Even when disabled,
  # the module system's path discovery validates those options exist,
  # so sops-nix must be loaded on any host that imports the bridge.
  # Servers get sops-nix transitively via the sops factory they
  # invoke; framework-13 doesn't use sops, so it needs the direct
  # import here.
  #
  # Delete this file once the legacy bridge no longer pulls in
  # sops-touching modules (or once framework-13 stops importing the
  # bridge entirely).
  flake.modules.nixos.framework-13 = {
    imports = [
      ../../../_needs_migration/modules
      inputs.sops-nix.nixosModules.sops
    ];
  };
}
