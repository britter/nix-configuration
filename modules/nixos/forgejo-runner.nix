_: {
  flake.modules.nixos.forgejo-runner =
    let
      # Fixed port of the runner's action-cache proxy. Job containers reach
      # the cache through the gateway of their podman network; pinning the
      # port lets the firewall below allow exactly that port instead of
      # exposing the whole host.
      cacheProxyPort = 32230;
    in
    {
      # The runner executes jobs in containers through the Docker API. Rootful
      # podman implements that API; enabling the docker-compatible socket lets
      # forgejo-runner (which connects to /run/docker.sock by default) work
      # without the docker daemon. The NixOS forgejo-runner module detects the
      # `:docker` label below, then adds the service to the `podman` group and
      # orders it after `podman.service` on its own.
      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
      };

      services.forgejo-runner.instances.codeberg = {
        enable = true;
        settings = {
          runner.labels = [
            # Matches `runs-on: docker`. The image is only a default: workflows
            # that set `container: image:` (like the renovate workflow on
            # britter/nixpkgs-pr) replace it for their job.
            "docker:docker://node:24-bookworm"
          ];
          cache.proxy_port = cacheProxyPort;
          # Jobs run untrusted code (the runner is registered on a public
          # repository, where pull-request workflows execute arbitrary
          # container images). Cap the resources a single job can consume so
          # the co-hosted forgejo instance survives a noisy or malicious job.
          # Bump if renovate jobs ever fail with OOM.
          container.options = "--memory=2g --cpus=1";
        };
      };

      # Egress policy for job containers. The runner executes untrusted
      # workflows on a public repository; the UniFi gateway (tofu/network)
      # cannot filter this traffic because it NATs behind this VM's own
      # address, so the policy lives here in the guest, hooked to the podman
      # bridges. Job containers may talk to the internet only:
      #
      # - FORWARD: drops to private/link-local/tailnet ranges. Container
      #   pairs on the same job network keep working (iif == oif); different
      #   job networks stay isolated from each other.
      # - INPUT: containers may only reach DNS (aardvark-dns) and the pinned
      #   action-cache proxy on their network gateway. Everything else on
      #   private addresses (sshd, nginx, beszel-agent, the tailnet IP) is
      #   dropped. The chains hook at priority -10 so these drops are
      #   evaluated before the generic port accepts of the nixos-fw input
      #   chain (priority 0).
      #
      # This switches the NixOS firewall rendering from the iptables to the
      # nftables backend. The firewall options in use (allowedTCPPorts etc.)
      # are backend-agnostic; no host uses iptables beyond the firewall.
      networking.nftables = {
        enable = true;
        tables.container-egress = {
          family = "inet";
          content = ''
            chain forward {
              type filter hook forward priority -10; policy accept;

              ct state established,related accept

              iifname "podman*" oifname "podman*" accept

              iifname "podman*" ip daddr {
                10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16,
                100.64.0.0/10, 169.254.0.0/16, 224.0.0.0/4, 240.0.0.0/4
              } counter drop

              iifname "podman*" ip6 daddr { fc00::/7, fe80::/10, ff00::/8 } counter drop
            }

            chain input {
              type filter hook input priority -10; policy accept;

              ct state established,related accept

              iifname "podman*" ip daddr 10.0.0.0/8 udp dport 53 accept
              iifname "podman*" ip daddr 10.0.0.0/8 tcp dport { 53, ${toString cacheProxyPort} } accept

              iifname "podman*" ip daddr {
                10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16,
                100.64.0.0/10, 169.254.0.0/16, 224.0.0.0/4, 240.0.0.0/4
              } counter drop
            }
          '';
        };
      };
    };
}
