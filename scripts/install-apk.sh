#!/bin/bash
set -e

APK_DIR="./package/apk"

# Update apk
echo "Updating apk..."
sudo apk update

# Install packages from apkfile
echo "Installing packages from apkfile..."
cat "$APK_DIR/apkfile"
packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  packages+=("$line")
done < "$APK_DIR/apkfile"
sudo apk add -y "${packages[@]}"

echo "Apk package installation completed!"
