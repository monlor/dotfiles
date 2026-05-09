#!/bin/bash

# Local AI/plugin development defaults to a hidden data directory, but can be
# pointed at any checkout by overriding LOCAL_PLUGIN_REPO.
export AI_CODE_HOME="${AI_CODE_HOME:-$HOME/.code}"
export CE_REPO="${CE_REPO:-$AI_CODE_HOME/plugins/compound-engineering-plugin}"
export GSTACK_REPO="${GSTACK_REPO:-$AI_CODE_HOME/gstack}"
export LOCAL_PLUGIN_REPO="${LOCAL_PLUGIN_REPO:-$CE_REPO}"

plugin-cli() {
  local repo="${LOCAL_PLUGIN_REPO}"
  if [ -n "${1:-}" ] && [ -d "$1" ]; then
    repo="$1"
    shift
  fi

  (
    cd "$repo" &&
      bun run src/index.ts "$@"
  )
}

ce-cli() {
  plugin-cli "${LOCAL_PLUGIN_REPO}" "$@"
}

codex-plugin() {
  local repo="${LOCAL_PLUGIN_REPO}"
  local plugin_path="${1:-$repo/plugins/compound-engineering}"

  if [ $# -gt 0 ]; then
    shift
  fi

  plugin-cli "$repo" install "$plugin_path" --to codex "$@"
}