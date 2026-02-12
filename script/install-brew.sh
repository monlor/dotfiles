#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <brew-list-file> [brew-list-file ...]"
  exit 1
fi

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Skip Homebrew install: current OS is not macOS."
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Please install Homebrew first."
  exit 1
fi

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    echo "skip missing file: $file"
    continue
  fi

  echo "==> brew bundle --file=$file"
  brew bundle --file="$file"
done
