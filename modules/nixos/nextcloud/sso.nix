_: {
  flake.modules.nixos.nextcloud =
    { config, lib, ... }:
    let
      occ = lib.getExe config.services.nextcloud.occ;
    in
    lib.mkIf config.services.nextcloud.enable {
      # user_oidc is packaged in nixpkgs for Nextcloud 35 (8.11.0, pinned
      # in pkgs/servers/nextcloud/packages/35.json) — extraApps keeps it
      # in lockstep with the Nextcloud package on upgrades, no app-store
      # drift.
      services.nextcloud.extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) user_oidc;
      };

      # Read by the oneshot below via occ's --clientsecret-file (the
      # secret must not land in argv or the world-readable unit file).
      # Rotation re-runs the oneshot, which re-encrypts the value into
      # the database.
      sops.secrets."nextcloud/keycloak-client-secret" = {
        owner = "nextcloud";
        restartUnits = [ "nextcloud-useroidc-config.service" ];
      };

      # Keycloak SSO (docs/plans/nextcloud-keycloak-sso.md): user_oidc
      # stores providers (secret included, encrypted) in the Nextcloud
      # database, so this oneshot keeps the DB row in sync with the
      # declaration — same pattern as nextcloud-richdocuments-config.
      # Idempotent: user_oidc:provider is an upsert by identifier;
      # re-running also clears the provider's JWKS cache (harmless).
      # --mapping-uid + --unique-uid 0 override the defaults (sub claim,
      # provider-hashed IDs) so the user ID is the realm
      # preferred_username and soft auto provisioning links onto the
      # existing local accounts instead of creating hashed-ID
      # duplicates. The tofu side of this client is
      # tofu/keycloak/client-nextcloud.tf (merged as PR #366).
      systemd.services.nextcloud-useroidc-config = {
        after = [ "nextcloud-setup.service" ];
        requires = [ "nextcloud-setup.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          ${occ} user_oidc:provider keycloak \
            --clientid nextcloud \
            --clientsecret-file ${config.sops.secrets."nextcloud/keycloak-client-secret".path} \
            --discoveryuri https://account.ritter.family/realms/homelab/.well-known/openid-configuration \
            --mapping-uid preferred_username \
            --unique-uid 0

          # Stage 1 (docs/plans/nextcloud-keycloak-sso.md): both doors
          # open. Stage 3 (Part E) flips this to 0 — the login page then
          # redirects to Keycloak and the password form is only reachable
          # with /login?direct=1.
          ${occ} config:app:set user_oidc allow_multiple_user_backends --type=string --value=1
        '';
      };
    };
}
