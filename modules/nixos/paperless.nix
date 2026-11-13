_: {
  flake.modules.nixos.paperless =
    { config, ... }:
    {
      sops.secrets."paperless/admin-password" = { };
      sops.secrets."paperless/keycloak-client-secret" = { };

      # Keycloak SSO (docs/plans/paperless-keycloak-sso.md): the allauth
      # provider block carries the client secret inside its JSON, and
      # `settings` renders into the world-readable systemd unit file —
      # so the whole PAPERLESS_SOCIALACCOUNT_PROVIDERS value lives in
      # this sops template, fed to the module's environmentFile (the
      # same path its docs use for PAPERLESS_DBPASS). A rotation
      # restarts the web service, which reads the env at start.
      sops.templates."paperless/sso.env" = {
        restartUnits = [ "paperless-web.service" ];
        # Single line — systemd EnvironmentFile values must not span
        # lines. The placeholder resolves at runtime to the sops secret
        # "paperless/keycloak-client-secret".
        content = ''
          PAPERLESS_SOCIALACCOUNT_PROVIDERS={"openid_connect":{"OAUTH_PKCE_ENABLED":true,"APPS":[{"provider_id":"keycloak","name":"Keycloak","client_id":"paperless","secret":"${
            config.sops.placeholder."paperless/keycloak-client-secret"
          }","settings":{"server_url":"https://account.ritter.family/realms/homelab/.well-known/openid-configuration","oauth_pkce_enabled":true,"token_auth_method":"client_secret_basic"}}]}}
        '';
      };

      services.paperless = {
        enable = true;
        port = 28981; # default; referenced by the proxy target below
        database.createLocally = true; # use the local postgres already running on this host
        passwordFile = config.sops.secrets."paperless/admin-password".path;
        environmentFile = config.sops.templates."paperless/sso.env".path;
        settings = {
          PAPERLESS_URL = "https://documents.ritter.family"; # required for CSRF/redirects behind proxy
          PAPERLESS_TIME_ZONE = "Europe/Berlin";
          PAPERLESS_OCR_LANGUAGE = "deu+eng"; # nixpkgs module auto-builds tesseract5 with these langs

          # Stage 1 (docs/plans/paperless-keycloak-sso.md): activate the
          # django-allauth OIDC provider; the provider block itself
          # (client id/secret, discovery URL, PKCE) comes from the sops
          # environmentFile. With regular login still on, this only adds
          # a "Sign in with Keycloak" button beside the password form.
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          # Stage 3: SSO is the only door on the web UI. Break-glass: the
          # Django admin at /admin/ still accepts the local admin
          # credentials (upstream guarantee), and removing this line
          # restores the password form on the next switch. See the plan's
          # Rollback section.
          PAPERLESS_DISABLE_REGULAR_LOGIN = true;
          # v3 allauth derives the rate-limited client IP from
          # X-Forwarded-For and trusts zero proxies by default —
          # trust exactly the one nginx hop on localhost, or all logins
          # share the proxy's single rate-limit bucket
          # (https://docs.paperless-ngx.com/migration-v3/).
          PAPERLESS_TRUSTED_PROXIES = "127.0.0.1,::1";
        };
      };

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "documents.${config.networking.hostName}.ritter.family";
            aliases = [ "documents.ritter.family" ];
            target = "http://localhost:28981";
            maxBodySize = "100M";
          }
        ];
      };
    };
}
