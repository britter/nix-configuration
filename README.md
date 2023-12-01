# nix-configuration

Flake based Nix configuration for my machines.

## Useful commands

### General

**Show store location of a module**

```shell
nix build <package> --print-out-paths --no-link
```

Where `<package>` would be something like `nixpkgs#cowsay`

**Run command without installing or nix-shell**

```shell
nix run <package> -- <args>
```

Where

- `<package>` would be something like `nixpkgs#exa`
- `<args>` would be something like `--tree --level 4` (in the case of exa).

Note that the `<package>` and `<args>` need to be separated by `--`

**Getting a package hash**

From URL:

```shell
nix run nixpkgs#nix-prefetch-url <url>
```

From git/GitHub:

```shell
nix run nixpkgs#nix-prefetch-git <url>
```

This will download the URL/git repository to the store and print the resulting hash.

### Flakes

**Switch to a machine configuration by host name**

```shell
sudo nixos switch --flake ".#<host>"
```

**Retrieve flake meta data**

```shell
nix flake metadata <flake url>
```

Flake url can be something like

- `.` (flake in CWD)
- `github:nixos/nixpkgs/nixos-unstable`

**Initialize a new flake**

```shell
nix flake init --template <template name>
```

**Update specific flake input**

```shell
nix flake lock --update-input <input name>
```

**Update flake with commit**

```shell
nix flake update --commit-lock-file
```

**Explore a flake**

```shell
nix flake show <flake url>
```

## Initializing a new machine

### NixOS

1. Install the latest NixOS release
2. Clone this repository using a nix shell that has git `nix shell nixpkgs#git`
3. Create a new folder under `hosts` that's named after the host.
4. Copy the `configuration.nix` and `hardware-configuration.nix` files from `etc/nixos/` into the new directory.
5. Add the new machine to `flake.nix`. Make sure the machine's host name and nixosConfiguration name match.
6. Repace `/etc/nixos` with a symbolic link to cloned repository.
7. Run `sudo nixos-rebuild switch --flake` to enable the flake based configuration for the new machine.

### macOS

1. Install nix using the [Determinate Systems nix installer](https://github.com/DeterminateSystems/nix-installer).
2. Clone this repository using a nix shell that has git `nix shell nixpkgs#git`
3. Create a new folder uder `hosts` that's names after the host.
4. Initialize a new configuration from the [examples in the nix-darwin repository](https://github.com/LnL7/nix-darwin/tree/19f75c2b45fbfc307ecfeb9dadc41a4c1e4fb980/modules/examples).
5. Add the new machine to `flake.nix`. Make sure the machine's host name and darwinConfiguration name match.
6. Inside the repository clone, run `nix run nix-darwin --extra-experimental-features 'nix-command flake' darwin-rebuild -- switch --flake .` (See for resolution of https://github.com/LnL7/nix-darwin/issues/721 in order to run darwin-rebuild from anywhere after that).
7. Apply the workaround documented in https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1782971499 is the issue is still unresolved.

### Raspberry Pi

This is the description for a network install that does not require the Raspberry Pi to be connected to a display.
Instead it's sufficient to connet it to the network via ethernet cable and ssh into the machine.
The SD card image will setup the root account and a user called `nixos` without password.
However the SSH service is configred to not accept empty passwords.
So in order to login via SSH, you need to pre-load your SSH key into the authorized_keys file of either the root user or the `nixos` user.
The first step is to download the bootable SD card image from the Hydra build system, see [this nixos.wiki entry](https://nixos.wiki/wiki/NixOS_on_ARM#Installation).

**Pre-load an SSH key into the image**

1. Use `nix run nixpkgs#parted parted <img>` to find out what exactly to mount. See [this stackoverflow answer](https://unix.stackexchange.com/a/156480) for details.
2. Mount the image file into a local directory by running

```shell
mkdir img
sudo mount -o loop,offset=<result from parted> <image file name> img
```

3. Generate an SSH key if you haven't already using the `ssh-keygen` tool.
4. The SD card image will setup a user called `nixos` on first boot. For that reason `/home/nixos` does not exist in the image you just mounted. Create the user home, and pre-load your SSH key as an authorized key:

```shell
sudo mkdir -p img/home/nixos/.ssh
sudo cp ~/.ssh/id_rsa.pub img/home/nixos/.ssh/authorized_keys
sudo chown -R 1000:100 img/home/nixos
sudo chmod -R 700 img/home/nixos
sudo chmod 600 img/home/nixos/authorized_keys
```

5. Unmount the image via `sudo umount img`
6. Use `nix run nixpkgs#rpi-imager` to run the Raspberry Pi imager and write the image to the SD card.

**After first boot**

1. Once the key is on the device, ssh into it as the `nixos` user.
2. Run `sudo nixos-generate-config` to generate the initial configuration.
3. IMPORTANT: You need to make two modifications to `/etc/nixos/configuration.nix`. If you forget to add this to the config, when you `nixos-rebuild switch` you won't be able to login anymore!
  - Configure the `nixos` user:

```nix
users.users.nixos = {
  isNormalUser = true;
  extraGroups = ["wheel"];
}
```

  - Enable the SSH services:

```nix
services.openssh = {
  enable = true;
  # require public key authentication for better security
  settings.PasswordAuthentication = false;
  settings.KbdInteractiveAuthentication = false;
  #settings.PermitRootLogin = "yes";
};
```

4. Start from 2. in the [NixOs](#nixos) section.

## Useful links

### Packages

- [NixOS Search](https://search.nixos.org/packages)
- [Nix User Repository](https://nur.nix-community.org/)
- [NixHub](https://nixhub.io)
- [Available programs](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/programs)
- GNOME
  - [NixOS manual entry](https://nixos.org/manual/nixos/stable/#chap-gnome)
  - [NixOS wiki entry](https://nixos.wiki/wiki/GNOME)

### Flakes

- [Flakes book](https://github.com/ryan4yin/nixos-and-flakes-book)
- [Using Flatpack](https://github.com/asininemonkey/nixos/blob/main/flatpak.nix)

### Configuration examples

- [Nix Configuration Examples](https://nixos.wiki/wiki/Configuration_Collection)
  - https://github.com/fortuneteller2k/nix-config
  - https://github.com/wiedzmin/nixos-config
  - https://github.com/jhol/dots
  - https://github.com/genebean/dots
  - https://github.com/icecreammatt/nixfiles
  - https://github.com/katexochen/nixos
  - https://github.com/msanft/nixos-conf

### Tools

#### General

- [lazygit](https://github.com/jesseduffield/lazygit)

#### Nix related

- [nix-jabba](https://codeberg.org/raboof/nix-jabba)
- [devenv.sh](https://devenv.sh)
- [statix linter](https://git.peppe.rs/languages/statix)
- [Alejandra formatterl](https://github.com/kamadorueda/alejandra)
- [Pre-commit-hooks.nix](https://github.com/cachix/pre-commit-hooks.nix)

### Nix on Raspberry Pi

- [SD Image builder](https://github.com/Robertof/nixos-docker-sd-image-builder)
- [pi-hole flake](https://github.com/mindsbackyard/pihole-flake)
