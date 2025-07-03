#!/bin/bash

if [[ -f $HOME/.local/bin/asdf ]]; then
  export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
fi