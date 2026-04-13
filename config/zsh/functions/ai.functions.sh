#!/bin/bash

# Local AI/plugin development defaults to a hidden data directory, but can be
# pointed at any checkout by overriding LOCAL_PLUGIN_REPO.
export AI_CODE_HOME="${AI_CODE_HOME:-$HOME/.code}"
export CE_REPO="${CE_REPO:-$AI_CODE_HOME/plugins/compound-engineering-plugin}"
export GSTACK_REPO="${GSTACK_REPO:-$AI_CODE_HOME/gstack}"
export LOCAL_PLUGIN_REPO="${LOCAL_PLUGIN_REPO:-$CE_REPO}"
export RTK_BIN="${RTK_BIN:-$(command -v rtk 2>/dev/null)}"

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

rtk-check() {
  if [ -z "$RTK_BIN" ]; then
    echo "rtk is not installed"
    return 1
  fi
  "$RTK_BIN" --help
}

rtk-codex() {
  if [ -z "$RTK_BIN" ]; then
    echo "rtk is not installed"
    return 1
  fi
  "$RTK_BIN" codex "$@"
}

rtk-claude() {
  if [ -z "$RTK_BIN" ]; then
    echo "rtk is not installed"
    return 1
  fi
  "$RTK_BIN" claude "$@"
}

rtk-opencode() {
  if [ -z "$RTK_BIN" ]; then
    echo "rtk is not installed"
    return 1
  fi
  "$RTK_BIN" opencode "$@"
}

rtk-openclaw() {
  if [ -z "$RTK_BIN" ]; then
    echo "rtk is not installed"
    return 1
  fi
  echo "OpenClaw currently fits RTK plugin/wrapper-style integration better than native init."
  echo "Use rtk with your OpenClaw-side plugin/hook setup after confirming the installed RTK version."
}
