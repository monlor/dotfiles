#!/bin/bash

if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  if [[ -f "${BREW_PREFIX}/opt/asdf/libexec/asdf.sh" ]]; then
    export ASDF_DIR="${BREW_PREFIX}/opt/asdf/libexec"
  fi
fi

if [[ -z "${ASDF_DATA_DIR:-}" ]]; then
  export ASDF_DATA_DIR="$HOME/.asdf"
fi

if [[ -n "${ASDF_DIR:-}" && -f "${ASDF_DIR}/asdf.sh" ]]; then
  # shellcheck disable=SC1090
  . "${ASDF_DIR}/asdf.sh"
fi
