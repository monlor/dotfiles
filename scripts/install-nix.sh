#!/bin/bash
set -e

NIX_DIR="./package/nix"
NIXFILE=${1:-"minimal.nix"}

echo "Installing Nix packages from: $NIXFILE"

if [[ ! -f "$NIX_DIR/$NIXFILE" ]]; then
    echo "Error: Package file $NIX_DIR/$NIXFILE not found"
    exit 1
fi

packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    # Trim whitespace
    pkg=$(echo "$line" | xargs)
    [[ -n "$pkg" ]] && packages+=("nixpkgs.$pkg")
done < "$NIX_DIR/$NIXFILE"

if [[ ${#packages[@]} -gt 0 ]]; then
    echo "Installing packages: ${packages[*]}"
    nix-env -iA "${packages[@]}"
else
    echo "No packages found in $NIXFILE"
fi

echo "Nix package installation completed!"