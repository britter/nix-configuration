{ pkgs, romm }:
let
  rommModule = (import ../../modules/nixos/romm.nix { }).flake.modules.nixos.romm;

  # Stub upstream that always responds with an X-Accel-Redirect header,
  # used to assert nginx's internal /library/ location actually serves
  # files (without depending on ROMM auth/DB state).
  xaccelStub = pkgs.writers.writePython3 "xaccel-stub" { flakeIgnore = [ "E305" ]; } ''
    from http.server import BaseHTTPRequestHandler, HTTPServer


    class H(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("X-Accel-Redirect", "/library/test-rom.gb")
            self.end_headers()

        def log_message(self, format, *args):
            pass
    HTTPServer(("127.0.0.1", 9999), H).serve_forever()
  '';
in
pkgs.testers.runNixOSTest {
  name = "romm-vm-test";

  nodes.machine = {
    imports = [ rommModule ];

    virtualisation = {
      memorySize = 2048;
      cores = 2;
      diskSize = 8192;
    };

    services.romm = {
      enable = true;
      package = romm;
      environmentFiles = [ "/etc/romm-test.env" ];
      nginx = {
        enable = true;
        hostName = "localhost";
      };
    };

    environment.etc."romm-test.env".text = ''
      ROMM_AUTH_SECRET_KEY=this-is-not-a-real-secret-key-just-for-tests
    '';

    systemd.services.xaccel-stub = {
      description = "X-Accel-Redirect test stub";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig.ExecStart = xaccelStub;
    };

    services.nginx.virtualHosts.localhost.locations."/test-xaccel" = {
      proxyPass = "http://127.0.0.1:9999";
      recommendedProxySettings = true;
    };
  };

  testScript = ''
    machine.wait_for_unit("mysql.service")
    machine.wait_for_unit("redis-romm.service")
    machine.wait_for_unit("romm-migrate.service")
    machine.wait_for_unit("romm-api.service")
    machine.wait_for_unit("romm-worker.service")
    machine.wait_for_unit("xaccel-stub.service")
    machine.wait_for_open_port(80)
    machine.wait_for_open_port(5000)
    machine.wait_for_open_port(9999)

    with subtest("frontend is served"):
        machine.succeed("curl -fsS http://localhost/ -o /tmp/index.html")
        machine.succeed("grep -q '<html' /tmp/index.html")

    with subtest("api heartbeat responds"):
        machine.wait_until_succeeds("curl -fsS http://localhost/api/heartbeat -o /tmp/heartbeat.json")
        machine.succeed("grep -q VERSION /tmp/heartbeat.json")

    with subtest("X-Accel-Redirect /library/ serves ROM files"):
        # Drop a file with the same ownership/mode ROMM creates: romm:romm 0640.
        machine.succeed(
            "install -d -o romm -g romm -m 0750 /var/lib/romm/library && "
            "install -o romm -g romm -m 0640 /dev/stdin "
            "/var/lib/romm/library/test-rom.gb <<<'NIX-TEST-ROM'"
        )
        # Direct external access must be 404 — the location is `internal`.
        code = machine.succeed(
            "curl -sS -o /dev/null -w '%{http_code}' "
            "http://localhost/library/test-rom.gb"
        ).strip()
        assert code == "404", f"expected 404 from internal /library/, got {code}"

        # Triggered via X-Accel-Redirect, the file body comes through.
        body = machine.succeed("curl -fsS http://localhost/test-xaccel").strip()
        assert body == "NIX-TEST-ROM", f"expected 'NIX-TEST-ROM', got {body!r}"
  '';
}
