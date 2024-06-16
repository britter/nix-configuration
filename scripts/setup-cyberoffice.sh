#!/usr/bin/env bash

# Source (with modifications): https://github.com/nix-community/nixos-anywhere/blob/46dc28f4f89b747084c7dd6d273b1278142220ce/docs/howtos/secrets.md

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# copy private ket to the temporary directory
cp ~/.ssh/cyberoffice_sops_id_ed25519 "$temp/etc/ssh/"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/cyberoffice_sops_id_ed25519"

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake '.#cyberoffice' root@192.168.178.199
