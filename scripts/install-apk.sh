#!/bin/bash
set -e

APK_DIR="./package/apk"
APKFILE=${1:-"minimal.apk"}

# Update apk
echo "Updating apk..."
sudo apk update

# Install packages from apkfile
echo "Installing packages from $APKFILE..."
if [[ ! -f "$APK_DIR/$APKFILE" ]]; then
    echo "Error: Package file $APK_DIR/$APKFILE not found"
    exit 1
fi
cat "$APK_DIR/$APKFILE"
packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  packages+=("$line")
done < "$APK_DIR/$APKFILE"
sudo apk add -y "${packages[@]}"

echo "Apk package installation completed!"
