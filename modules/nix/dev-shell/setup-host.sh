# Source (with modifications): https://github.com/nix-community/nixos-anywhere/blob/46dc28f4f89b747084c7dd6d273b1278142220ce/docs/howtos/secrets.md

read -ra choices <<< "$CONFIGURATIONS"
CONFIGURATION=$(gum choose --header "Select configuration" "${choices[@]}")
IP=$(gum input --header "Host to deploy configuration to" --placeholder "IP address")
gum confirm "Deploy $CONFIGURATION to $IP?"

echo "Setting up $CONFIGURATION on $IP..."

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# copy public ket to the temporary directory
sops -- decrypt "$HOST_KEYS_FILE" --extract "[\"$CONFIGURATION\"][\"public-key\"]" --output "$temp/etc/ssh/ssh_host_ed25519_key.pub"
# Set the correct permissions so sshd will accept the key
chmod 644 "$temp/etc/ssh/ssh_host_ed25519_key.pub"

# copy private ket to the temporary directory
sops -- decrypt "$HOST_KEYS_FILE" --extract "[\"$CONFIGURATION\"][\"private-key\"]" --output "$temp/etc/ssh/ssh_host_ed25519_key"
# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

# Install NixOS to the host system with our secrets
nixos-anywhere --extra-files "$temp" --flake ".#$CONFIGURATION" "root@$IP"

echo "Done setting up $CONFIGURATION on $IP!"
