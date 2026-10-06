_: {
  flake.modules.homeManager.nono-base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Empty skeleton for a nono profile. Every key the tool knows about is
      # present so a profile that sets nothing renders as a complete file
      # with empty/null values. `meta.name` defaults to the profile name.
      emptyProfile = name: {
        extends = [ ];
        meta = {
          inherit name;
          version = null;
          description = null;
          author = null;
        };
        security = {
          signal_mode = null;
          process_info_mode = null;
          ipc_mode = null;
          capability_elevation = null;
          approval_backends = { };
          approval_defaults = null;
          wsl2_proxy_policy = null;
        };
        groups = {
          include = [ ];
          exclude = [ ];
        };
        commands = {
          allow = [ ];
          deny = [ ];
        };
        filesystem = {
          allow = [ ];
          read = [ ];
          write = [ ];
          allow_file = [ ];
          read_file = [ ];
          write_file = [ ];
          unix_socket = [ ];
          unix_socket_bind = [ ];
          unix_socket_dir = [ ];
          unix_socket_dir_bind = [ ];
          unix_socket_subtree = [ ];
          unix_socket_subtree_bind = [ ];
          deny = [ ];
          bypass_protection = [ ];
          suppress_save_prompt = [ ];
        };
        network = {
          block = false;
          allow_http2 = false;
          allow_domain = [ ];
          deny_domain = [ ];
          open_port = [ ];
          open_port_range = [ ];
          listen_port = [ ];
          listen_port_range = [ ];
          connect_port = [ ];
          no_proxy = [ ];
          custom_credentials = { };
          tls_intercept = null;
          upstream_proxy = null;
          upstream_bypass = [ ];
        };
        diagnostics.suppress_system_services = [ ];
        linux = {
          af_unix_mediation = null;
          sandbox_policy = null;
        };
        env_credentials = { };
        credential_capture = { };
        credential_providers = { };
        credential_routes = [ ];
        workdir.access = "none";
        hooks = { };
        session_hooks = { };
        rollback = {
          exclude_patterns = [ ];
          exclude_globs = [ ];
        };
        interactive = false;
        skipdirs = [ ];
        packs = [ ];
        command_args = [ ];
        unsafe_macos_seatbelt_rules = [ ];
      };

      renderProfile = name: value: lib.recursiveUpdate (emptyProfile name) value;

      cfg = config.programs.nono;
      jsonFormat = pkgs.formats.json { };
    in
    {
      options.programs.nono = {
        enable = lib.mkEnableOption "nono sandbox";

        package = lib.mkPackageOption pkgs "nono" { };

        profiles = lib.mkOption {
          description = ''
            nono sandbox profiles, rendered to ~/.config/nono/profiles/<name>.json.
            The attribute name is the profile name. Values not set explicitly
            are filled in with empty defaults; `meta.name` defaults to the
            profile name.
          '';
          type = lib.types.attrsOf jsonFormat.type;
          default = { };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        xdg.configFile = lib.mapAttrs' (name: value: {
          name = "nono/profiles/${name}.json";
          value.source = jsonFormat.generate "nono-profile-${name}" (renderProfile name value);
        }) cfg.profiles;
      };
    };
}
