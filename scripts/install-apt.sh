#!/bin/bash
set -e

APT_DIR="./package/apt"

# Add repositories
echo "Adding apt repositories..."
# Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo tee /etc/apt/trusted.gpg.d/kubernetes.asc > /dev/null
echo "deb https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# HashiCorp
if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then 
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
fi
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update apt
echo "Updating apt..."
sudo apt update

# Install packages from aptfile
echo "Installing packages from aptfile..."
cat "$APT_DIR/aptfile"
packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  packages+=("$line")
done < "$APT_DIR/aptfile"
sudo apt install -y "${packages[@]}"

echo "Apt package installation completed!"
