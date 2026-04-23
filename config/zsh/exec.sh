#!/bin/bash

if [ -z "$USER" ]; then
  export USER=$(whoami)
fi

if [ -z "$HOME" ]; then
  export HOME=$(echo ~)
fi

export PATH="$HOME/.local/bin:${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

if [[ -f "$HOME/.dotfiles/script/load-asdf.sh" ]]; then
  # shellcheck disable=SC1090
  . "$HOME/.dotfiles/script/load-asdf.sh"
fi

if [ -f ~/.secrets ]; then
  source ~/.secrets
fi

"$@"
