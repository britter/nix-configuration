#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure
#! nix-shell -p nixos-anywhere -I nixos-anywhere=https://github.com/nix-community/nixos-anywhere
set -euo pipefail

# Source (with modifications): https://github.com/nix-community/nixos-anywhere/blob/46dc28f4f89b747084c7dd6d273b1278142220ce/docs/howtos/secrets.md

# Capture host to configure
if [ -z "$1" ]; then
  echo "Please provide the host to setup as an argument!"
  exit 1
fi

host="$1"
ip="${2:-192.168.178.199}"

echo "Setting up $host via $ip..."

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
hostKey="$HOME/.ssh/ssh_${host}_ed25519_key"
echo "Sending $hostKey to $host:/etc/ssh/ssh_host_ed25519_key"
cp "$hostKey" "$temp/etc/ssh/ssh_host_ed25519_key"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake ".#$host" "root@$ip"

echo "Done setting up $host via $ip!"
