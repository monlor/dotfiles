#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APT_DIR="$(dirname "$SCRIPT_DIR")"

# Add repositories
echo "Adding apt repositories..."
# Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo tee /etc/apt/trusted.gpg.d/kubernetes.asc > /dev/null
sudo cp "$APT_DIR/sources/kubernetes.list" /etc/apt/sources.list.d/

# HashiCorp
if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then 
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
fi
sudo cp "$APT_DIR/sources/hashicorp.list" /etc/apt/sources.list.d/

# Helm
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo tee /etc/apt/trusted.gpg.d/helm.asc > /dev/null
sudo cp "$APT_DIR/sources/helm.list" /etc/apt/sources.list.d/

# Update apt
echo "Updating apt..."
sudo apt update

# Install packages from aptfile
echo "Installing packages from aptfile..."
packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  packages+=("$line")
done < "$APT_DIR/aptfile"
sudo apt install -y "${packages[@]}"

# Install additional tools
echo "Installing additional tools..."
# Starship
curl -sS https://starship.rs/install.sh | sh -s -- -f

# Pyenv
if [ ! -d ~/.pyenv ]; then
  curl https://pyenv.run | bash
fi

# GitHub packages
bash -c '~/.local/bin/ghpkg mikefarah/yq sunny0826/kubecm ahmetb/kubectx AliyunContainerService/image-syncer helmfile/helmfile nektos/act utkuozdemir/pv-migrate'

echo "Apt package installation completed!"