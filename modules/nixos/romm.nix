_: {
  flake.modules.nixos.romm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.romm;
      pkg = cfg.package;

      redisServerName = "romm";

      useSocketAuth = cfg.database.createLocally && cfg.database.driver != "postgresql";

      defaultSettings = lib.filterAttrs (_: v: v != null) (
        {
          ROMM_BASE_PATH = cfg.stateDir;
          ROMM_PORT = toString cfg.port;
          ROMM_DB_DRIVER = cfg.database.driver;
          DB_HOST = cfg.database.host;
          DB_PORT = toString cfg.database.port;
          DB_NAME = cfg.database.name;
          DB_USER = cfg.database.user;
          REDIS_HOST = cfg.redis.host;
          REDIS_PORT = toString cfg.redis.port;
        }
        // lib.optionalAttrs useSocketAuth {
          # ensureUsers creates 'romm'@'localhost' with the unix_socket auth
          # plugin, so the OS user authenticates without a password. ROMM
          # still requires a non-empty DB_PASSWD to construct the URL, but
          # mariadb-connector ignores it when unix_socket is in the query.
          DB_PASSWD = "unused";
          DB_QUERY_JSON = ''{"unix_socket": "/run/mysqld/mysqld.sock"}'';
        }
      );

      serviceDefaults = {
        environment = lib.mapAttrs (_: v: if lib.isBool v then lib.boolToString v else toString v) (
          defaultSettings // cfg.settings
        );
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.stateDir;
          EnvironmentFile = cfg.environmentFiles;
          # Hardening (mirrors stirling-pdf upstream module).
          AmbientCapabilities = "";
          CapabilityBoundingSet = "";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          PrivateUsers = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ cfg.stateDir ];
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "~@cpu-emulation @debug @keyring @mount @obsolete @privileged @clock @setuid @chown"
          ];
          # 0027 (group readable) so a co-located nginx serving the
          # library via X-Accel-Redirect can read files; 0077 otherwise.
          UMask = if cfg.nginx.enable then "0027" else "0077";
        };
      };
    in
    {
      options.services.romm = {
        enable = lib.mkEnableOption "the ROMM ROM manager";

        package = lib.mkPackageOption pkgs "romm" { };

        user = lib.mkOption {
          type = lib.types.str;
          default = "romm";
          description = "User to run ROMM under.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "romm";
          description = "Group to run ROMM under.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 5000;
          description = "TCP port the gunicorn backend listens on (loopback).";
        };

        workers = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
          description = "Number of gunicorn worker processes.";
        };

        stateDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/romm";
          description = ''
            ROMM_BASE_PATH. Holds library/, resources/, assets/, config/,
            launchbox/ and sync/ subdirectories.
          '';
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.oneOf [
              lib.types.str
              lib.types.int
              lib.types.bool
            ]
          );
          default = { };
          example = {
            ENABLE_SCHEDULED_RESCAN = true;
            LOGLEVEL = "INFO";
          };
          description = ''
            Freeform ROMM_* environment variables. Overrides defaults derived
            from the typed `database`, `redis`, `port`, and `stateDir` options.
            See env.template in upstream for the complete list.
          '';
        };

        environmentFiles = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          example = [ "/run/secrets/romm.env" ];
          description = ''
            systemd EnvironmentFile= entries.

            ROMM refuses to start unless `ROMM_AUTH_SECRET_KEY` is set.
            It is the instance secret used to sign session cookies, CSRF
            tokens, and JWTs, and must be stable across restarts (rotating
            it silently logs every user out). It is unrelated to the
            admin user's password; the admin account is created via the
            setup wizard on first boot.

            Generate a 32-byte hex value with:

            ```
            nix run nixpkgs#openssl -- rand -hex 32
            ```

            and ship it to the unit via sops-nix, agenix, or any file
            outside the Nix store. The file's contents should look like:

            ```
            ROMM_AUTH_SECRET_KEY=2f1c4b6e8d3a5f7e9c2b4d6f8a0c1e3d5f7a9b2c4d6e8f0a1b3c5d7e9f1a3b5c
            ```

            Optional but common entries in the same file:

            - `DB_PASSWD` — required when `database.createLocally = false`
              (skipped when the local MariaDB path uses unix_socket auth).
            - Metadata-source API keys: `IGDB_CLIENT_ID`,
              `IGDB_CLIENT_SECRET`, `MOBYGAMES_API_KEY`,
              `SCREENSCRAPER_USER`, `SCREENSCRAPER_PASSWORD`,
              `STEAMGRIDDB_API_KEY`, `RETROACHIEVEMENTS_API_KEY`.
          '';
        };

        database = {
          createLocally = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether to enable a local MariaDB instance and create the
              database and user. When false, configure connection details
              via the other `database.*` options and supply DB_PASSWD in
              `environmentFiles`.
            '';
          };
          driver = lib.mkOption {
            type = lib.types.enum [
              "mariadb"
              "mysql"
              "postgresql"
            ];
            default = "mariadb";
            description = "ROMM_DB_DRIVER value.";
          };
          host = lib.mkOption {
            type = lib.types.str;
            default = "localhost";
            description = "DB_HOST.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 3306;
            description = "DB_PORT.";
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "romm";
            description = "DB_NAME.";
          };
          user = lib.mkOption {
            type = lib.types.str;
            default = "romm";
            description = "DB_USER.";
          };
        };

        redis = {
          createLocally = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether to enable a dedicated local Redis (Valkey) server.
              When false, set `redis.host`/`redis.port` and supply
              REDIS_PASSWORD via `environmentFiles`.
            '';
          };
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "REDIS_HOST.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 6479;
            description = "REDIS_PORT.";
          };
        };

        nginx = {
          enable = lib.mkEnableOption "an nginx virtualHost serving the frontend and proxying API traffic";
          hostName = lib.mkOption {
            type = lib.types.str;
            example = "roms.example.com";
            description = "FQDN for the nginx virtualHost.";
          };
        };

        enableScheduler = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Run rqscheduler. Required if any ENABLE_SCHEDULED_* setting is true.";
        };

        enableWatcher = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Run watchfiles against the library to trigger rescans on filesystem changes.";
        };
      };

      config = lib.mkIf cfg.enable {
        users.users.${cfg.user} = lib.mkIf (cfg.user == "romm") {
          isSystemUser = true;
          inherit (cfg) group;
          home = cfg.stateDir;
        };
        users.groups.${cfg.group} = lib.mkIf (cfg.group == "romm") { };

        # nginx must read library files when serving them via X-Accel-Redirect.
        users.users.nginx.extraGroups = lib.mkIf cfg.nginx.enable [ cfg.group ];

        systemd.tmpfiles.rules = [
          "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} -"
          "d ${cfg.stateDir}/library 0750 ${cfg.user} ${cfg.group} -"
          "d ${cfg.stateDir}/resources 0750 ${cfg.user} ${cfg.group} -"
          "d ${cfg.stateDir}/assets 0750 ${cfg.user} ${cfg.group} -"
          "d ${cfg.stateDir}/config 0750 ${cfg.user} ${cfg.group} -"
          "d ${cfg.stateDir}/launchbox 0750 ${cfg.user} ${cfg.group} -"
          "d ${cfg.stateDir}/sync 0750 ${cfg.user} ${cfg.group} -"
        ];

        services.mysql = lib.mkIf (cfg.database.createLocally && cfg.database.driver != "postgresql") {
          enable = true;
          package = lib.mkDefault pkgs.mariadb;
          ensureDatabases = [ cfg.database.name ];
          ensureUsers = [
            {
              name = cfg.database.user;
              ensurePermissions."${cfg.database.name}.*" = "ALL PRIVILEGES";
            }
          ];
        };

        services.postgresql = lib.mkIf (cfg.database.createLocally && cfg.database.driver == "postgresql") {
          enable = true;
          ensureDatabases = [ cfg.database.name ];
          ensureUsers = [
            {
              name = cfg.database.user;
              ensureDBOwnership = true;
            }
          ];
        };

        services.redis.servers.${redisServerName} = lib.mkIf cfg.redis.createLocally {
          enable = true;
          port = cfg.redis.port;
          bind = cfg.redis.host;
        };

        systemd.services.romm-migrate = lib.recursiveUpdate serviceDefaults {
          description = "ROMM: run alembic migrations and seed caches";
          after = [
            "network.target"
          ]
          ++ lib.optional (cfg.database.createLocally && cfg.database.driver != "postgresql") "mysql.service"
          ++ lib.optional (
            cfg.database.createLocally && cfg.database.driver == "postgresql"
          ) "postgresql.service"
          ++ lib.optional cfg.redis.createLocally "redis-${redisServerName}.service";
          requires =
            lib.optional (cfg.database.createLocally && cfg.database.driver != "postgresql") "mysql.service"
            ++ lib.optional (
              cfg.database.createLocally && cfg.database.driver == "postgresql"
            ) "postgresql.service"
            ++ lib.optional cfg.redis.createLocally "redis-${redisServerName}.service";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = [
              "${pkg}/bin/romm-migrate"
              "${pkg}/bin/romm-startup"
            ];
          };
        };

        systemd.services.romm-api = lib.recursiveUpdate serviceDefaults {
          description = "ROMM: gunicorn API server";
          after = [ "romm-migrate.service" ];
          requires = [ "romm-migrate.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.ExecStart = "${pkg}/bin/romm-api --bind 127.0.0.1:${toString cfg.port} --workers ${toString cfg.workers}";
        };

        systemd.services.romm-worker = lib.recursiveUpdate serviceDefaults {
          description = "ROMM: rq background worker";
          after = [ "romm-migrate.service" ];
          requires = [ "romm-migrate.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.ExecStart = "${pkg}/bin/romm-worker high default low";
        };

        systemd.services.romm-scheduler = lib.mkIf cfg.enableScheduler (
          lib.recursiveUpdate serviceDefaults {
            description = "ROMM: rqscheduler";
            after = [ "romm-migrate.service" ];
            requires = [ "romm-migrate.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.ExecStart = "${pkg}/bin/romm-scheduler";
          }
        );

        systemd.services.romm-watcher = lib.mkIf cfg.enableWatcher (
          lib.recursiveUpdate serviceDefaults {
            description = "ROMM: filesystem watcher";
            after = [ "romm-api.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.ExecStart = ''
              ${pkg.passthru.pythonEnv}/bin/watchfiles \
                "python3 watcher.py ${cfg.stateDir}/library" ${cfg.stateDir}/library
            '';
          }
        );

        services.nginx = lib.mkIf cfg.nginx.enable {
          enable = true;
          virtualHosts.${cfg.nginx.hostName} = {
            locations = {
              "/" = {
                root = "${pkg}/share/romm/frontend";
                tryFiles = "$uri $uri/ /index.html";
              };
              "/assets/romm/resources/".alias = "${cfg.stateDir}/resources/";
              # X-Accel-Redirect target for ROMM's ROM/firmware download
              # endpoints. Not directly reachable from outside.
              "/library/" = {
                alias = "${cfg.stateDir}/library/";
                extraConfig = "internal;";
              };
              "/api" = {
                proxyPass = "http://127.0.0.1:${toString cfg.port}";
                recommendedProxySettings = true;
              };
              "/ws" = {
                proxyPass = "http://127.0.0.1:${toString cfg.port}";
                proxyWebsockets = true;
                recommendedProxySettings = true;
                extraConfig = "proxy_read_timeout 86400;";
              };
              "/netplay" = {
                proxyPass = "http://127.0.0.1:${toString cfg.port}";
                proxyWebsockets = true;
                recommendedProxySettings = true;
              };
            };
            extraConfig = ''
              client_max_body_size 0;
            '';
          };
        };
      };
    };
}
