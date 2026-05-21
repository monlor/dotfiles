#!/bin/bash

if [ -z "${MISE_BIN:-}" ]; then
  if command -v mise >/dev/null 2>&1; then
    MISE_BIN="$(command -v mise)"
  elif [ -x "$HOME/.local/bin/mise" ]; then
    MISE_BIN="$HOME/.local/bin/mise"
  elif command -v brew >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix)"
    if [ -x "${BREW_PREFIX}/bin/mise" ]; then
      MISE_BIN="${BREW_PREFIX}/bin/mise"
    fi
  fi
fi

if [ -n "${MISE_BIN:-}" ]; then
  case "${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}" in
    zsh*)
      eval "$("$MISE_BIN" activate zsh)"
      ;;
    *bash)
      eval "$("$MISE_BIN" activate bash)"
      ;;
  esac
fi
