# Source (with modifications): https://github.com/nix-community/nixos-anywhere/blob/46dc28f4f89b747084c7dd6d273b1278142220ce/docs/howtos/secrets.md

read -ra choices <<< "$CONFIGURATIONS"
CONFIGURATION=$(gum choose --header "Select configuration" "${choices[@]}")
IP=$(gum input --header "Host to deploy configuration to" --placeholder "IP address")
gum confirm "Deploy $CONFIGURATION to $IP?"

gum style --foreground 212 --bold --margin "1 0" "Setting up $CONFIGURATION on $IP"

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  gum log --level error "setup-host must be run inside the nix-configuration repository"
  exit 1
fi
host_keys_path="$repo_root/$HOST_KEYS_FILE"

# Try to load existing host keys from the sops store for this configuration.
if sops -- decrypt "$host_keys_path" --extract "[\"$CONFIGURATION\"][\"public-key\"]" --output "$temp/etc/ssh/ssh_host_ed25519_key.pub" 2>/dev/null; then
  chmod 644 "$temp/etc/ssh/ssh_host_ed25519_key.pub"
  sops -- decrypt "$host_keys_path" --extract "[\"$CONFIGURATION\"][\"private-key\"]" --output "$temp/etc/ssh/ssh_host_ed25519_key"
  chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"
  gum log --level info "Loaded host keys for $CONFIGURATION from sops store"
else
  gum log --level warn "Host keys for $CONFIGURATION not found in sops store"
  if gum confirm "Generate new keys and add them?"; then
    ssh-keygen -t ed25519 -N "" -C "root@$CONFIGURATION" -f "$temp/etc/ssh/ssh_host_ed25519_key"

    public_key_json=$(jq -Rs . < "$temp/etc/ssh/ssh_host_ed25519_key.pub")
    private_key_json=$(jq -Rs . < "$temp/etc/ssh/ssh_host_ed25519_key")

    sops set "$host_keys_path" "[\"$CONFIGURATION\"][\"public-key\"]" "$public_key_json"
    sops set "$host_keys_path" "[\"$CONFIGURATION\"][\"private-key\"]" "$private_key_json"

    gum log --level info "Added host keys for $CONFIGURATION to $HOST_KEYS_FILE"
  else
    gum log --level error "Aborted: cannot proceed without host keys"
    exit 1
  fi
fi

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake ".#$CONFIGURATION" "root@$IP"

gum style --foreground 42 --bold --margin "1 0" "Done! $CONFIGURATION deployed to $IP"
