#!/bin/sh
set -eu

CODEX_ROOT="${HOME}/.codex"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
REGISTRY_PATH="${REPO_ROOT}/config/ai/registry.json"

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

REGISTRY_PATH="${REGISTRY_PATH}" python3 - <<'PY'
from pathlib import Path
import json
import os
import re
import shutil

codex_root = Path.home() / ".codex"
registry_path = Path(os.environ["REGISTRY_PATH"]).expanduser()


def expand_path(value: str) -> Path:
    return Path(value).expanduser()


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
        return
    if path.is_dir():
        shutil.rmtree(path)


def cleanup_skill_root(skill_root: Path) -> None:
    if not skill_root.exists():
        return

    for manifest_path in skill_root.glob(".ai-external-skills-*.json"):
        try:
            payload = json.loads(manifest_path.read_text())
        except json.JSONDecodeError:
            payload = {}

        for name in payload.get("managed", []):
            remove_path(skill_root / name)

        manifest_path.unlink()

    for entry in skill_root.iterdir():
        if (
            entry.name.startswith("gsd-")
            or entry.name == "paseo"
            or entry.name.startswith("paseo-")
            or entry.name == "pinchtab"
        ):
            remove_path(entry)


if registry_path.exists():
    registry = json.loads(registry_path.read_text())
    for tool_config in registry.get("tools", {}).values():
        skills_path = tool_config.get("skills_path")
        if skills_path:
            cleanup_skill_root(expand_path(skills_path))

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
