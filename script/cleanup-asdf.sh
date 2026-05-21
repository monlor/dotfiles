#!/usr/bin/env bash

set -euo pipefail

APPLY=false
KEEP_PACKAGE=false

usage() {
  cat <<'EOF'
Usage: ./script/cleanup-asdf.sh [--apply] [--keep-package]

Options:
  --apply         Execute removals. Default is dry-run.
  --keep-package  Keep the asdf system package/binary; only remove local data.
  -h, --help      Show this help message.

What it cleans:
  - ~/.asdf
  - ~/.asdfrc
  - common asdf completion cache files
  - optional package-manager install of asdf (brew/apt/dnf/yum/apk)

Notes:
  - Does not remove .tool-versions because mise may still use it.
  - Does not modify shell rc files.
EOF
}

log() {
  printf '%s\n' "$*"
}

run_or_echo() {
  if [[ "$APPLY" == true ]]; then
    "$@"
  else
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  fi
}

remove_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    run_or_echo rm -rf "$path"
  else
    log "skip missing: $path"
  fi
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

cleanup_package() {
  if [[ "$KEEP_PACKAGE" == true ]]; then
    log "keep package: asdf"
    return 0
  fi

  if has_cmd brew && brew list asdf >/dev/null 2>&1; then
    run_or_echo brew uninstall asdf
    return 0
  fi

  if has_cmd apt-get && dpkg -s asdf >/dev/null 2>&1; then
    run_or_echo sudo apt-get remove -y asdf
    return 0
  fi

  if has_cmd dnf && rpm -q asdf >/dev/null 2>&1; then
    run_or_echo sudo dnf remove -y asdf
    return 0
  fi

  if has_cmd yum && rpm -q asdf >/dev/null 2>&1; then
    run_or_echo sudo yum remove -y asdf
    return 0
  fi

  if has_cmd apk && apk info -e asdf >/dev/null 2>&1; then
    run_or_echo sudo apk del asdf
    return 0
  fi

  log "skip package uninstall: no supported asdf package detected"
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply)
        APPLY=true
        ;;
      --keep-package)
        KEEP_PACKAGE=true
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log "unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done

  log "asdf cleanup mode: $([[ "$APPLY" == true ]] && echo apply || echo dry-run)"

  remove_path "$HOME/.asdf"
  remove_path "$HOME/.asdfrc"
  remove_path "$HOME/.oh-my-zsh/cache/completions/_asdf"
  remove_path "$HOME/.zcompdump-asdf"

  cleanup_package

  log "done"
}

main "$@"
