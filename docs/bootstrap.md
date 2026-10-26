# Bootstrapping a new machine

How to add a new machine to the configuration. The NixOS, macOS, and Raspberry
Pi sections below all start from the same first step: register the host in the
flake.

## Register the host in the flake

Every host — physical or VM — needs a directory under `modules/hosts/<name>/`.
The easiest way is to copy an existing host that is closest to the new one:

1. Create `modules/hosts/<name>/`.
2. Copy `configuration.nix` and `flake-parts.nix` from an existing host and
   adapt them:
   - `configuration.nix` defines the host aspect
     (`flake.modules.nixos.<name>`) as an import list of aspect names plus
     host-specific settings. The host name and the `nixosConfiguration` name
     must match.
   - `flake-parts.nix` turns the aspect into a
     `nixosConfigurations.<name>` entry via `flake.lib.mkNixos` — set the
     correct system there (e.g. `aarch64-linux` for a Raspberry Pi).
3. If the machine uses sops secrets, add its age key to the root `.sops.yaml`
   and create `modules/hosts/<name>/secrets.yaml` (see the sops section in
   `AGENTS.md` and the README).
4. Run `nix flake check` to verify the new host evaluates.

## NixOS

1. Install the latest NixOS release.
2. Clone this repository using a nix shell that has git:
   `nix shell nixpkgs#git`.
3. Register the host in the flake (see above).
4. Replace `/etc/nixos` with a symbolic link to the cloned repository.
5. Run `sudo nixos-rebuild switch --flake` to enable the flake based
   configuration for the new machine.

## VMs (Proxmox)

Optional: build a new VM image if changes are required:

```shell
nix build .#nixosConfigurations.minimal-server-iso.config.system.build.isoImage
```

1. Define a new VM using the Proxmox OpenTofu configuration in `tofu/proxmox/`.
   Make sure to reference the right ISO.
2. Wait for the VM to boot into the installer.
3. Register the host in the flake (see above).
4. Install the VM using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
   by running:

```shell
nix run github:nix-community/nixos-anywhere -- --flake '.#<host-config>' root@<vm-ip>
```

In case the machine uses sops secrets, the SSH host keys need to be sent to
the host during setup. Use the `setup-host` command from the dev shell
(`modules/nix/dev-shell/`): it picks a configuration and target IP
interactively and either loads the host keys from the sops store
(`modules/nix/dev-shell/host-keys.yaml`) or generates and stores new ones.

Redeploy the machine remotely via:

```shell
nixos-rebuild switch --fast --flake .#<host-config> \
    --target-host root@<host-ip> \
    --build-host root@<host-ip>
```

See https://www.haskellforall.com/2023/01/announcing-nixos-rebuild-new-deployment.html

Servers deployed this way are then kept up to date automatically by
[comin](https://github.com/nlewo/comin), which pulls from this repository and
switches when `main` moves.

## macOS

No macOS host currently exists in this flake (there is no `nix-darwin` input),
but the setup below worked before and is kept for when one is added again.
`nix-darwin` would need to be added as a flake input first.

1. Install nix using the [Determinate Systems nix installer](https://github.com/DeterminateSystems/nix-installer).
2. Clone this repository using a nix shell that has git: `nix shell nixpkgs#git`.
3. Create a new folder for the host (see "Register the host in the flake"
   above; the `flake-parts.nix` step does not apply to darwin configurations).
4. Initialize a new configuration from the [examples in the nix-darwin repository](https://github.com/LnL7/nix-darwin/tree/19f75c2b45fbfc307ecfeb9dadc41a4c1e4fb980/modules/examples).
5. Add the new machine to the flake. Make sure the machine's host name and
   `darwinConfiguration` name match.
6. Inside the repository clone, run `nix run nix-darwin --extra-experimental-features 'nix-command flake' darwin-rebuild -- switch --flake .`
   (See https://github.com/LnL7/nix-darwin/issues/721 for how to run
   darwin-rebuild from anywhere after that.)
7. Apply the workaround documented in https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1782971499
   if the issue is still unresolved.

## Raspberry Pi

This is the description for a network install that does not require the
Raspberry Pi to be connected to a display. Instead it's sufficient to connect
it to the network via ethernet cable and ssh into the machine. The SD card
image will set up the root account and a user called `nixos` without password.
However the SSH service is configured to not accept empty passwords. So in
order to log in via SSH, you need to pre-load your SSH key into the
`authorized_keys` file of either the root user or the `nixos` user. The first
step is to download the bootable SD card image from the Hydra build system,
see [this nixos.wiki entry](https://nixos.wiki/wiki/NixOS_on_ARM#Installation).

### Pre-load an SSH key into the image

1. Use `nix run nixpkgs#parted <img>` to find out what exactly to mount. See
   [this stackoverflow answer](https://unix.stackexchange.com/a/156480) for details.
2. Mount the image file into a local directory by running:

```shell
mkdir img
sudo mount -o loop,offset=<result from parted> <image file name> img
```

3. Generate an SSH key if you haven't already, using the `ssh-keygen` tool.
4. The SD card image will set up a user called `nixos` on first boot. For that
   reason `/home/nixos` does not exist in the image you just mounted. Create
   the user home, and pre-load your SSH key as an authorized key:

```shell
sudo mkdir -p img/home/nixos/.ssh
sudo cp ~/.ssh/id_rsa.pub img/home/nixos/.ssh/authorized_keys
sudo chown -R 1000:100 img/home/nixos
sudo chmod -R 700 img/home/nixos
sudo chmod 600 img/home/nixos/authorized_keys
```

5. Unmount the image via `sudo umount img`.
6. Use `nix run nixpkgs#rpi-imager` to run the Raspberry Pi imager and write
   the image to the SD card.

### After first boot

1. Once the key is on the device, ssh into it as the `nixos` user.
2. Run `sudo nixos-generate-config` to generate the initial configuration.
3. IMPORTANT: You need to make two modifications to `/etc/nixos/configuration.nix`.
   If you forget to add this to the config, when you `nixos-rebuild switch`
   you won't be able to log in anymore!

- Configure the `nixos` user:

```nix
users.users.nixos = {
  isNormalUser = true;
  extraGroups = ["wheel"];
};
```

- Enable the SSH service:

```nix
services.openssh = {
  enable = true;
  # require public key authentication for better security
  settings.PasswordAuthentication = false;
  settings.KbdInteractiveAuthentication = false;
  #settings.PermitRootLogin = "yes";
};
```

4. Continue with the NixOS section above.
