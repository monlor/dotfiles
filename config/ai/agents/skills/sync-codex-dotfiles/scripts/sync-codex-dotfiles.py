#!/usr/bin/env python3
"""Sync reusable Codex config into dotfiles without local machine state."""

from __future__ import annotations

import argparse
import difflib
import filecmp
import os
import re
import shutil
import sys
from pathlib import Path


HOME = Path.home()
DEFAULT_SOURCE = Path(os.environ.get("CODEX_HOME", HOME / ".codex")).expanduser()
DEFAULT_TARGET = Path(
    os.environ.get("DOTFILES_CODEX_HOME", HOME / ".dotfiles/config/ai/codex")
).expanduser()

ALLOWLIST = ("AGENTS.md", "agents", "keybindings.json", "prompts", "git-hooks")
DROP_SECTIONS = (
    "projects",
    "projects.",
    "hooks.state",
    "hooks.state.",
    "desktop.open-in-target-preferences.perPath",
    "mcp_servers.node_repl",
    "mcp_servers.node_repl.",
    "apps.",
    "notice.",
)
DROP_TOP_LEVEL_KEYS = {"notify"}
DROP_MARKETPLACE_KEYS = {"last_updated", "last_revision"}
LOCAL_PATH_RE = re.compile(r'^\s*source\s*=\s*"(/Users/|~/|/private/|/var/|/tmp/)')


def section_from(line: str) -> str | None:
    match = re.match(r"^\s*\[+(.+?)\]+\s*(?:#.*)?$", line)
    return match.group(1) if match else None


def key_from(line: str) -> str | None:
    match = re.match(r"^\s*([A-Za-z0-9_.-]+)\s*=", line)
    return match.group(1) if match else None


def should_drop_section(section: str) -> bool:
    return any(section == prefix or section.startswith(prefix) for prefix in DROP_SECTIONS)


def balance_delta(line: str) -> int:
    # Good enough for multiline arrays in Codex config, where strings do not contain brackets.
    return line.count("[") - line.count("]")


def sanitize_config(text: str) -> str:
    lines = text.splitlines(keepends=True)
    output: list[str] = []
    block: list[str] = []
    current_section: str | None = None

    def flush() -> None:
        nonlocal block, current_section
        if not block:
            return
        output.extend(sanitize_block(current_section, block))
        block = []

    for line in lines:
        section = section_from(line)
        if section is not None:
            flush()
            current_section = section
        block.append(line)
    flush()

    sanitized = "".join(output)
    sanitized = re.sub(r"\n{3,}", "\n\n", sanitized).rstrip() + "\n"
    return sanitized


def sanitize_block(section: str | None, block: list[str]) -> list[str]:
    if section is None:
        return sanitize_top_level(block)
    if should_drop_section(section):
        return []
    if section.startswith("marketplaces."):
        return sanitize_marketplace(block)
    return block


def sanitize_top_level(block: list[str]) -> list[str]:
    output: list[str] = []
    dropping_value = False
    value_balance = 0

    for line in block:
        if dropping_value:
            value_balance += balance_delta(line)
            if value_balance <= 0:
                dropping_value = False
            continue

        key = key_from(line)
        if key in DROP_TOP_LEVEL_KEYS:
            value_balance = balance_delta(line)
            dropping_value = value_balance > 0
            continue
        output.append(line)

    return output


def sanitize_marketplace(block: list[str]) -> list[str]:
    has_local_source_type = any(re.match(r'^\s*source_type\s*=\s*"local"', line) for line in block)
    has_local_source = any(LOCAL_PATH_RE.match(line) for line in block)
    if has_local_source_type or has_local_source:
        return []
    return [line for line in block if key_from(line) not in DROP_MARKETPLACE_KEYS]


def unified_diff(old: str, new: str, old_name: str, new_name: str) -> str:
    return "".join(
        difflib.unified_diff(
            old.splitlines(keepends=True),
            new.splitlines(keepends=True),
            fromfile=old_name,
            tofile=new_name,
        )
    )


def same_path(left: Path, right: Path) -> bool:
    try:
        return left.resolve() == right.resolve()
    except FileNotFoundError:
        return False


def dirs_equal(left: Path, right: Path) -> bool:
    if not right.exists():
        return False
    cmp = filecmp.dircmp(left, right)
    if cmp.left_only or cmp.right_only or cmp.diff_files or cmp.funny_files:
        return False
    return all(dirs_equal(Path(cmp.left) / name, Path(cmp.right) / name) for name in cmp.common_dirs)


def sync_path(source: Path, target: Path, apply: bool) -> bool:
    if not source.exists():
        return False
    if same_path(source, target):
        print(f"skip same path: {target}")
        return False
    if source.is_dir():
        changed = not dirs_equal(source, target)
        if not changed:
            return False
        print(f"{'sync' if apply else 'would sync'} dir: {source} -> {target}")
        if apply:
            if target.exists() or target.is_symlink():
                if target.is_dir() and not target.is_symlink():
                    shutil.rmtree(target)
                else:
                    target.unlink()
            shutil.copytree(source, target, symlinks=True)
        return True

    old = target.read_text() if target.exists() else ""
    new = source.read_text()
    if old == new:
        return False
    print(unified_diff(old, new, str(target), str(source)), end="")
    if apply:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(new)
    return True


def sync_config(source: Path, target: Path, apply: bool) -> bool:
    new = sanitize_config(source.read_text())
    old = target.read_text() if target.exists() else ""
    if old == new:
        print("config.toml already up to date")
        return False
    print(unified_diff(old, new, str(target), f"sanitized:{source}"), end="")
    if apply:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(new)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--target", type=Path, default=DEFAULT_TARGET)
    parser.add_argument("--apply", action="store_true", help="write changes instead of dry-run")
    args = parser.parse_args()

    source = args.source.expanduser()
    target = args.target.expanduser()
    if not source.exists():
        print(f"source does not exist: {source}", file=sys.stderr)
        return 2
    if not (source / "config.toml").exists():
        print(f"missing source config: {source / 'config.toml'}", file=sys.stderr)
        return 2

    if not args.apply:
        print("dry-run only; pass --apply to write changes")

    changed = sync_config(source / "config.toml", target / "config.toml", args.apply)
    for name in ALLOWLIST:
        changed = sync_path(source / name, target / name, args.apply) or changed

    if not changed:
        print("no changes")
    elif args.apply:
        print("sync complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
