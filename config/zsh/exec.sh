#!/bin/sh

if [ -z "$USER" ]; then
  export USER=$(whoami)
fi

if [ -z "$HOME" ]; then
  export HOME=$(echo ~)
fi

export PATH=$HOME/.local/bin:$HOME/.asdf/shims:$PATH

if [ -f ~/.secrets ]; then
  source ~/.secrets
fi

"$@"