#!/bin/bash

if [ -z "$USER" ]; then
  export USER=$(whoami)
fi

if [ -z "$HOME" ]; then
  export HOME=$(echo ~)
fi

export PATH="$HOME/.local/bin:$PATH"

if [[ -f "$HOME/.dotfiles/script/load-mise.sh" ]]; then
  # shellcheck disable=SC1090
  . "$HOME/.dotfiles/script/load-mise.sh"
fi

if [ -f ~/.secrets ]; then
  source ~/.secrets
fi

"$@"
