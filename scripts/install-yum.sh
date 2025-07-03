#!/bin/bash
set -e

YUM_DIR="./package/yum"

# EPEL
echo "Installing EPEL and yum-utils..."
sudo yum install -y epel-release yum-utils

# Add repositories
echo "Adding yum repositories..."
# HashiCorp
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Kubernetes
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
EOF

# Update yum
echo "Updating yum..."
sudo yum makecache

# Install packages from yum
echo "Installing packages from yumfile..."
packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  packages+=("$line")
done < "$YUM_DIR/yumfile"
sudo yum install -y "${packages[@]}"

echo "Yum package installation completed!"
