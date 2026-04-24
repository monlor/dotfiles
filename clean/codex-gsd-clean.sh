#!/bin/sh
set -eu

CODEX_ROOT="${HOME}/.codex"

remove_path() {
  target="$1"
  if [ -L "$target" ] || [ -f "$target" ]; then
    rm -f "$target"
    return
  fi
  if [ -d "$target" ]; then
    rm -rf "$target"
  fi
}

if [ -d "${CODEX_ROOT}/skills" ]; then
  find "${CODEX_ROOT}/skills" -maxdepth 1 -name 'gsd-*' -exec rm -rf {} +
fi

if [ -d "${CODEX_ROOT}/agents" ]; then
  find "${CODEX_ROOT}/agents" -maxdepth 1 -name 'gsd-*' -exec rm -rf {} +
fi

if [ -d "${CODEX_ROOT}/hooks" ]; then
  find "${CODEX_ROOT}/hooks" -maxdepth 1 -name 'gsd-*' -exec rm -rf {} +
fi

remove_path "${CODEX_ROOT}/get-shit-done"
remove_path "${CODEX_ROOT}/gsd-file-manifest.json"

python3 - <<'PY'
from pathlib import Path
import json
import re

codex_root = Path.home() / ".codex"

config_path = codex_root / "config.toml"
if config_path.exists():
    content = config_path.read_text()
    content = re.sub(
        r'^\[agents\.gsd-[^\]]+\]\n(?:.*\n)*?(?=^\[|\Z)',
        "",
        content,
        flags=re.MULTILINE,
    )
    content = re.sub(r"^\[agents\]\n", "", content, flags=re.MULTILINE)
    content = re.sub(
        r"^# GSD Agent Configuration — managed by get-shit-done installer\n",
        "",
        content,
        flags=re.MULTILINE,
    )
    config_path.write_text(re.sub(r"\n{3,}", "\n\n", content).rstrip() + "\n")

hooks_path = codex_root / "hooks.json"
if hooks_path.exists():
    payload = json.loads(hooks_path.read_text())
    cleaned = {}
    for event_name, groups in payload.get("hooks", {}).items():
        next_groups = []
        for group in groups:
            hooks = []
            for hook in group.get("hooks", []):
                command = hook.get("command", "")
                if "gsd-" in command or "/get-shit-done/" in command:
                    continue
                hooks.append(hook)
            if hooks:
                next_groups.append({"hooks": hooks})
        if next_groups:
            cleaned[event_name] = next_groups
    hooks_path.write_text(json.dumps({"hooks": cleaned}, indent=2, ensure_ascii=True) + "\n")
PY

echo "Cleaned GSD artifacts from ${CODEX_ROOT}"
