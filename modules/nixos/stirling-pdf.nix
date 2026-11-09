_: {
  flake.modules.nixos.stirling-pdf =
    { config, pkgs, ... }:
    let
      deu-traineddata = pkgs.fetchurl {
        url = "https://github.com/tesseract-ocr/tessdata/raw/refs/heads/main/deu.traineddata";
        hash = "sha256-iWs7SVZQOrnaoQKF2zMIgbLXS3DYibeSYsxTS57GmaQ=";
      };
    in
    {
      # Keycloak SSO (docs/plans/stirling-pdf-keycloak-sso.md), following
      # the forgejo/beszel-hub singleton cut: OIDC config and its sops
      # wiring live in the service aspect. The client secret and the
      # initial break-glass admin password come from sops; everything
      # else is plain app configuration. Stage 1 keeps password login
      # next to SSO — Part E of the plan adds SECURITY_LOGINMETHOD =
      # "oauth2" once the first SSO login has landed and carries the
      # Admin role.
      sops.secrets."stirling-pdf/client-secret" = { };
      sops.secrets."stirling-pdf/admin-password" = { };
      sops.templates."stirling-pdf/sso.env" = {
        content = ''
          SECURITY_OAUTH2_CLIENT_KEYCLOAK_CLIENTSECRET=${config.sops.placeholder."stirling-pdf/client-secret"}
          SECURITY_INITIALLOGIN_PASSWORD=${config.sops.placeholder."stirling-pdf/admin-password"}
        '';
      };

      services.stirling-pdf = {
        enable = true;
        package = pkgs.stirling-pdf-free;
        environment = {
          INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
          SYSTEM_ENABLEANALYTICS = "false";
          SERVER_PORT = 8090;

          SECURITY_ENABLELOGIN = true;
          SECURITY_OAUTH2_ENABLED = true;

          SECURITY_OAUTH2_CLIENT_KEYCLOAK_ISSUER = "https://account.ritter.family/realms/homelab";
          SECURITY_OAUTH2_CLIENT_KEYCLOAK_CLIENTID = "stirling-pdf";
          SECURITY_OAUTH2_CLIENT_KEYCLOAK_SCOPES = "openid, profile, email";
          # preferred_username = the realm's "bene" user; Keycloak only
          # delivers claims, the app's own Workspace/Users model stays
          # authoritative (see tofu/keycloak/README.md).
          SECURITY_OAUTH2_CLIENT_KEYCLOAK_USEASUSERNAME = "preferred_username";
          # autoCreateUser + no blockRegistration: the realm's
          # admin-provisioned userbase is the outer shell (registration
          # is off), so the first SSO sign-in simply creates the one
          # seat — same pattern as the Beszel onboarding.
          SECURITY_OAUTH2_AUTOCREATEUSER = true;
          SECURITY_OAUTH2_BLOCKREGISTRATION = false;

          # First admin for the empty user database (login was never on
          # before). Both settings are inert once users exist; the
          # account is the break-glass for Part E's password-disabled
          # state (rollback = remove SECURITY_LOGINMETHOD).
          SECURITY_INITIALLOGIN_USERNAME = "admin";
        };
        environmentFiles = [ config.sops.templates."stirling-pdf/sso.env".path ];
      };

      systemd.tmpfiles.rules = [
        "d /usr/share/tessdata 0755 root root"
        "L+ /usr/share/tessdata/deu.traineddata - - - - ${deu-traineddata}"
      ];

      services.https-proxy = {
        enable = true;
        configurations = [
          {
            fqdn = "pdf.${config.networking.hostName}.ritter.family";
            aliases = [ "pdf.ritter.family" ];
            target = "http://localhost:8090";
            maxBodySize = "100M";
          }
        ];
      };
    };
}
