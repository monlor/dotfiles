#!/bin/bash
set -e

DNF_DIR="./package/dnf"
DNFFILE=${1:-"minimal.dnf"}

# Install dnf plugins
echo "Installing dnf plugins core..."
sudo dnf install -y dnf-plugins-core

# Add repositories
echo "Adding dnf repositories..."
# HashiCorp - dnf5 compatible: download .repo file directly
sudo curl -fsSL https://rpm.releases.hashicorp.com/fedora/hashicorp.repo -o /etc/yum.repos.d/hashicorp.repo

# Kubernetes
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
EOF

# Update dnf cache
echo "Updating dnf cache..."
sudo dnf makecache

# Install packages from file
echo "Installing packages from $DNFFILE..."
if [[ ! -f "$DNF_DIR/$DNFFILE" ]]; then
    echo "Error: Package file $DNF_DIR/$DNFFILE not found"
    exit 1
fi
cat "$DNF_DIR/$DNFFILE"
packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  packages+=("$line")
done < "$DNF_DIR/$DNFFILE"
sudo dnf install -y "${packages[@]}"

echo "Package installation completed!"