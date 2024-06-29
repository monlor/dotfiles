#!/bin/bash

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT ]] && export PATH="$PYENV_ROOT/bin:$PATH"

if type pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
