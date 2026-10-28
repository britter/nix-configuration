{ config, ... }:
let
  inherit (config.flake.modules.nixos) forgejo-runner;
in
{
  flake.modules.nixos.codeberg-runner-on-srv-prod-6 =
    { config, ... }:
    {
      imports = [ forgejo-runner ];

      sops.secrets."forgejo-runner/token" = {
        # The token reaches the runner through systemd LoadCredential, which
        # is only mounted when the service starts, so rotation needs a restart.
        restartUnits = [ "forgejo-runner-codeberg.service" ];
      };

      services.forgejo-runner.instances.codeberg = {
        settings.server.connections.codeberg = {
          url = "https://codeberg.org";
          # UUID + token pair from registering the runner at
          # https://codeberg.org/britter/nixpkgs-pr/settings/actions/runners.
          # The UUID acts as the runner's login name and is not confidential;
          # the token is the secret half and comes from sops below. Upstream
          # has no uuid_url yet, so the UUID cannot be loaded from a file (see
          # the FIXME in nixpkgs' forgejo-runner module) and sits here in
          # plain text.
          uuid = "b5e63c38-0903-44ad-8184-b6abdbac2624";
        };
        # Rendered to `token_url = file:$CREDENTIALS_DIRECTORY/...` and read
        # through systemd LoadCredential; the value never lands in the nix
        # store or the unit file.
        secrets.server.connections.codeberg.token_url = config.sops.secrets."forgejo-runner/token".path;
      };
    };
}
