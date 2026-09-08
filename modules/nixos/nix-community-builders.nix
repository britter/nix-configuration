{ config, ... }:
{
  flake.modules.nixos.nix-community-builders =
    { pkgs, ... }:
    let
      # The public half of this key is registered for `britter` in
      # nix-community/infra. Remote builds are started by the nix daemon, so the
      # file has to be readable by root and must not carry a passphrase.
      sshUser = "britter";
      sshKey = "/home/bene/.ssh/id_ed25519";
      linuxFeatures = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
    in
    {
      # These machines exist to build nixpkgs pull requests and nothing else.
      # Everyone with access to them is a trusted user there, so any of them can
      # substitute arbitrary content for a path we asked to be built: outputs
      # come back unsigned, and input-addressed store paths carry nothing to
      # verify them against. See https://nix-community.org/community-builders/
      #
      # `distributedBuilds = false` therefore writes /etc/nix/machines but sets
      # `builders = ` in nix.conf, overriding nix's `@/etc/nix/machines` default.
      # Nothing is offloaded unless a command asks for it, which keeps the
      # builders out of this host's own system closure -- the one place where a
      # poisoned path would end up running as root. Opting in is per command;
      # see `nixpkgs-review-remote` below.
      nix.distributedBuilds = false;

      nix.buildMachines = [
        {
          hostName = "build-box.nix-community.org";
          inherit sshUser sshKey;
          systems = [ "x86_64-linux" ];
          maxJobs = 8;
          supportedFeatures = linuxFeatures;
        }
        {
          hostName = "aarch64-build-box.nix-community.org";
          inherit sshUser sshKey;
          systems = [ "aarch64-linux" ];
          maxJobs = 16;
          supportedFeatures = linuxFeatures;
        }
        {
          hostName = "darwin-build-box.nix-community.org";
          inherit sshUser sshKey;
          systems = [ "aarch64-darwin" ];
          maxJobs = 4;
          supportedFeatures = [ "big-parallel" ];
        }
      ];

      nix.settings = {
        # Have the builders fetch unchanged dependencies from cache.nixos.org
        # themselves. Only the paths a pull request actually rebuilds then come
        # back from the builder, which keeps the unsigned set as small as it can
        # be.
        builders-use-substitutes = true;
        # `builders` is a restricted setting, so overriding it on the command
        # line requires the invoking user to be trusted by the daemon.
        trusted-users = [ "@wheel" ];
      };

      # Host keys from https://nix-community.org/community-builders/. Also makes
      # interactive ssh to the boxes work without a fingerprint prompt.
      programs.ssh.knownHosts = {
        "build-box.nix-community.org".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElIQ54qAy7Dh63rBudYKdbzJHrrbrrMXLYl7Pkmk88H";
        "aarch64-build-box.nix-community.org".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9uyfhyli+BRtk64y+niqtb+sKquRGGZ87f4YRc8EE1";
        "darwin-build-box.nix-community.org".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKMHhlcn7fUpUuiOFeIhDqBzBNFsbNqq+NpzuGX3e6zv";
      };

      home-manager.sharedModules = [
        {
          imports = [ config.flake.modules.homeManager.fish ];

          home.packages = [ pkgs.nixpkgs-review ];

          # `--max-jobs 0` keeps the laptop out of the build entirely, which is
          # the whole point of reaching for the community machines. The garbage
          # collection afterwards is what keeps their output from lingering:
          # nixpkgs-review builds with `--no-link` and leaves plain symlinks in
          # ~/.cache/nixpkgs-review, none of which are GC roots, so once the
          # review shell has exited every path the builders sent is unreachable.
          # Left in the store it would stay valid forever and could be reused by
          # a later build instead of being fetched from a signed cache.
          programs.fish.functions.nixpkgs-review-remote = ''
            nixpkgs-review pr \
              --build-args '--builders @/etc/nix/machines --max-jobs 0' \
              $argv
            set --local review_status $status

            echo "Dropping store paths received from the community builders..."
            nix-collect-garbage

            return $review_status
          '';
        }
      ];
    };
}
