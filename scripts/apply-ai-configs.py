#!/usr/bin/env python3
"""Apply portable AI harness configs without overwriting secrets."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import stat
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
AI_ROOT = REPO_ROOT / "config" / "ai"
HOME = Path.home()

SECRET_KEY_RE = re.compile(
    r"(api[_-]?key|auth_token|access_token|secret|password|token)$",
    re.IGNORECASE,
)

# MCP servers managed by this repo. Live extras such as computer-use are kept.
MANAGED_MCP = (
    "context7",
    "playwright",
    "codebase-memory-mcp",
    "codebase-memory",
    "tolaria",
)

# Writable JSON files: merge template into live, never clobber secrets.
JSON_MERGES = (
    {
        "template": AI_ROOT / "claude" / "settings.json",
        "target": HOME / ".claude" / "settings.json",
        "keys": (
            "hooks",
            "enabledPlugins",
            "extraKnownMarketplaces",
            "skipDangerousModePermissionPrompt",
            "skipWorkflowUsageWarning",
            "theme",
            "teammateMode",
            "inputNeededNotifEnabled",
            "agentPushNotifEnabled",
            "model",
        ),
        "merge_env": True,
        "merge_hooks": True,
        "merge_maps": ("enabledPlugins", "extraKnownMarketplaces"),
    },
    {
        "template": AI_ROOT / "claude" / "mcp.json",
        "target": HOME / ".claude" / "mcp.json",
        "keys": ("mcpServers",),
        "replace_mcp": True,
    },
    {
        "template": AI_ROOT / "pi" / "settings.json",
        "target": HOME / ".pi" / "agent" / "settings.json",
        "keys": (
            "defaultProvider",
            "defaultModel",
            "defaultThinkingLevel",
            "packages",
            "enableSkillCommands",
        ),
        "drop_keys": ("enabledModels", "skills"),
    },
    {
        "template": AI_ROOT / "pi" / "mcp.json",
        "target": HOME / ".pi" / "agent" / "mcp.json",
        "keys": ("mcpServers",),
        "replace_mcp": True,
    },
    {
        "template": AI_ROOT / "pi" / "web-search.json",
        "target": HOME / ".pi" / "agent" / "web-search.json",
        "keys": ("ssrf",),
        "deep": True,
    },
    {
        "template": AI_ROOT / "opencode" / "opencode.json",
        "target": HOME / ".config" / "opencode" / "opencode.json",
        "keys": ("skills", "mcp", "provider", "model", "small_model", "enabled_providers"),
        "deep": True,
        "replace_mcp": True,
        "replace_keys": ("provider", "model", "small_model", "enabled_providers"),
        "merge_lists": ("plugin",),
        "drop_keys": ("instructions",),
    },
)

ADHD_REPO = "https://github.com/ayghri/i-have-adhd.git"
ADHD_DIR = HOME / ".config" / "opencode" / "vendor" / "i-have-adhd"
ADHD_PLUGIN = ADHD_DIR / ".opencode" / "plugins" / "i-have-adhd.mjs"
ADHD_ALWAYS = HOME / ".config" / "opencode" / ".i-have-adhd-always"

# Codex-equivalent Claude plugins: marketplace source, then plugin@marketplace.
CLAUDE_PLUGINS = (
    ("ayghri/i-have-adhd", "i-have-adhd@i-have-adhd"),
    ("addyosmani/agent-skills", "agent-skills@addy-agent-skills"),
    ("citrolabs/ego-lite", "browser-skills@ego-agent-skills"),
)

# Init-only files: copy when missing. Never replace an existing secret-bearing file.
COPY_IF_MISSING = (
    (AI_ROOT / "pi" / "models.json", HOME / ".pi" / "agent" / "models.json"),
    (AI_ROOT / "codex" / "config.toml", HOME / ".codex" / "config.toml"),
)

LINKS = (
    (AI_ROOT / "AGENTS.md", HOME / ".agents" / "AGENTS.md"),
    (AI_ROOT / "AGENTS.md", HOME / ".claude" / "CLAUDE.md"),
    (AI_ROOT / "claude" / "hooks" / "cbm-session-reminder", HOME / ".claude" / "hooks" / "cbm-session-reminder"),
    (AI_ROOT / "claude" / "hooks" / "cbm-subagent-reminder", HOME / ".claude" / "hooks" / "cbm-subagent-reminder"),
    (
        AI_ROOT / "claude" / "hooks" / "cbm-code-discovery-gate",
        HOME / ".claude" / "hooks" / "cbm-code-discovery-gate",
    ),
    (
        AI_ROOT / "claude" / "agents" / "codebase-memory.md",
        HOME / ".claude" / "agents" / "codebase-memory.md",
    ),
    (
        AI_ROOT / "claude" / "agents" / "codebase-memory-scout.md",
        HOME / ".claude" / "agents" / "codebase-memory-scout.md",
    ),
    (
        AI_ROOT / "claude" / "agents" / "codebase-memory-auditor.md",
        HOME / ".claude" / "agents" / "codebase-memory-auditor.md",
    ),
    (
        AI_ROOT / "claude" / "skills" / "codebase-memory",
        HOME / ".claude" / "skills" / "codebase-memory",
    ),
    (AI_ROOT / "codex" / "keybindings.json", HOME / ".codex" / "keybindings.json"),
    (AI_ROOT / "codex" / "hooks.json", HOME / ".codex" / "hooks.json"),
    (AI_ROOT / "codex" / "agents", HOME / ".codex" / "agents"),
    (AI_ROOT / "codex" / "prompts", HOME / ".codex" / "prompts"),
    (AI_ROOT / "codex" / "git-hooks", HOME / ".codex" / "git-hooks"),
    (AI_ROOT / "pi" / "APPEND_SYSTEM.md", HOME / ".pi" / "agent" / "APPEND_SYSTEM.md"),
    (AI_ROOT / "pi" / "extensions" / "paseo-hooks.ts", HOME / ".pi" / "agent" / "extensions" / "paseo-hooks.ts"),
    (
        AI_ROOT / "pi" / "extensions" / "model-tool-aliases.ts",
        HOME / ".pi" / "agent" / "extensions" / "model-tool-aliases.ts",
    ),
    (AI_ROOT / "pi" / "extensions" / "cbmem.ts", HOME / ".pi" / "agent" / "extensions" / "cbmem.ts"),
)


def is_secret_key(key: str) -> bool:
    return bool(SECRET_KEY_RE.search(key))


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def write_json(path: Path, data: dict, *, dry_run: bool) -> None:
    text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    if dry_run:
        print(f"write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def deep_merge(dst: object, src: object) -> object:
    if isinstance(dst, dict) and isinstance(src, dict):
        out = dict(dst)
        for key, value in src.items():
            if is_secret_key(key) and key in dst and dst[key]:
                continue
            if key in out:
                out[key] = deep_merge(out[key], value)
            else:
                out[key] = value
        return out
    return src


def hook_command(entry: object) -> str:
    if not isinstance(entry, dict):
        return ""
    hooks = entry.get("hooks") or []
    if isinstance(hooks, list) and hooks and isinstance(hooks[0], dict):
        return str(hooks[0].get("command") or "")
    return ""


def merge_hooks(live: object, template: object) -> dict:
    live_hooks = dict(live) if isinstance(live, dict) else {}
    template_hooks = dict(template) if isinstance(template, dict) else {}
    out = dict(live_hooks)
    for event, entries in template_hooks.items():
        live_entries = list(out.get(event) or []) if isinstance(out.get(event), list) else []
        seen = {hook_command(item) for item in live_entries}
        seen.discard("")
        for entry in entries if isinstance(entries, list) else []:
            command = hook_command(entry)
            if command and command in seen:
                continue
            live_entries.append(entry)
            if command:
                seen.add(command)
        out[event] = live_entries
    return out


def merge_maps(live: object, template: object) -> dict:
    out = dict(live) if isinstance(live, dict) else {}
    template_map = dict(template) if isinstance(template, dict) else {}
    for key, value in template_map.items():
        if is_secret_key(key) and out.get(key):
            continue
        out[key] = value
    return out


def merge_selected(
    live: dict,
    template: dict,
    keys: tuple[str, ...],
    *,
    deep: bool,
    merge_hooks_key: bool = False,
) -> dict:
    out = dict(live)
    for key in keys:
        if key not in template:
            continue
        value = template[key]
        if merge_hooks_key and key == "hooks":
            out[key] = merge_hooks(out.get(key), value)
        elif deep and key in out:
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = value
    return out


def plugin_item_key(item: object) -> str:
    if isinstance(item, list) and item:
        raw = str(item[0])
    else:
        raw = str(item)
    suffix = "i-have-adhd/.opencode/plugins/i-have-adhd.mjs"
    if raw.endswith(suffix):
        return suffix
    return raw


def unique_union(live: object, template: object) -> list:
    live_list = list(live) if isinstance(live, list) else []
    template_list = list(template) if isinstance(template, list) else []
    seen: set[str] = set()
    out: list = []
    for item in template_list + live_list:
        key = plugin_item_key(item)
        if key in seen:
            continue
        seen.add(key)
        out.append(item)
    return out


def replace_mcp_servers(live_mcp: object, template_mcp: object) -> dict:
    live = dict(live_mcp) if isinstance(live_mcp, dict) else {}
    template = dict(template_mcp) if isinstance(template_mcp, dict) else {}
    for name in MANAGED_MCP:
        live.pop(name, None)
    live.update(template)
    return live


def merge_env(live: dict, template: dict) -> dict:
    live_env = dict(live.get("env") or {})
    template_env = dict(template.get("env") or {})
    for key, value in template_env.items():
        if is_secret_key(key) and live_env.get(key):
            continue
        if key not in live_env or not is_secret_key(key):
            live_env[key] = value
    live["env"] = live_env
    return live


def replace_with_link(target: Path, source: Path, *, dry_run: bool) -> None:
    source = source.resolve()
    if target.is_symlink() and target.resolve() == source:
        return
    print(f"link {target} -> {source}")
    if dry_run:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink() or target.is_file():
        target.unlink()
    elif target.is_dir():
        # Only replace empty placeholder dirs; never delete a populated runtime dir.
        try:
            next(target.iterdir())
        except StopIteration:
            target.rmdir()
        else:
            print(f"skip {target}: directory already has files")
            return
    os.symlink(source, target)


def chmod_executable(path: Path, *, dry_run: bool) -> None:
    if dry_run or not path.exists():
        return
    mode = path.stat().st_mode
    path.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def copy_if_missing(source: Path, target: Path, *, dry_run: bool) -> None:
    if target.exists() or target.is_symlink():
        return
    print(f"create {target} from {source}")
    if dry_run:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


def apply_json_merges(*, dry_run: bool) -> None:
    for spec in JSON_MERGES:
        template = load_json(spec["template"])
        target: Path = spec["target"]
        live = load_json(target)
        merged = merge_selected(
            live,
            template,
            spec["keys"],
            deep=bool(spec.get("deep")),
            merge_hooks_key=bool(spec.get("merge_hooks")),
        )
        if spec.get("merge_env"):
            merged = merge_env(merged, template)
        for key in spec.get("merge_maps") or ():
            if key in template:
                merged[key] = merge_maps(live.get(key), template[key])
        if spec.get("replace_mcp"):
            for mcp_key in ("mcpServers", "mcp"):
                if mcp_key in template:
                    merged[mcp_key] = replace_mcp_servers(
                        live.get(mcp_key), template.get(mcp_key)
                    )
        for key in spec.get("replace_keys") or ():
            if key in template:
                merged[key] = template[key]
        for key in spec.get("merge_lists") or ():
            if key in template:
                merged[key] = unique_union(live.get(key), template[key])
        for key in spec.get("drop_keys") or ():
            merged.pop(key, None)
        if merged == live and target.exists():
            continue
        print(f"merge {target}")
        write_json(target, merged, dry_run=dry_run)


def write_text_file(target: Path, text: str, *, dry_run: bool, reason: str) -> None:
    current = ""
    if target.exists() and not target.is_symlink():
        current = target.read_text()
    if current == text:
        return
    print(f"write {target} ({reason})")
    if dry_run:
        return
    if target.is_symlink() or target.is_file():
        target.unlink()
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)


def write_harness_agents(*, dry_run: bool) -> None:
    shared = (AI_ROOT / "AGENTS.md").read_text().rstrip()
    write_text_file(
        HOME / ".codex" / "AGENTS.md",
        shared + "\n",
        dry_run=dry_run,
        reason="codex-owned copy of shared rules",
    )
    write_text_file(
        HOME / ".pi" / "agent" / "AGENTS.md",
        shared + "\n",
        dry_run=dry_run,
        reason="pi-owned copy of shared rules",
    )
    write_text_file(
        HOME / ".config" / "opencode" / "AGENTS.md",
        (AI_ROOT / "opencode" / "AGENTS.md").read_text().rstrip() + "\n\n" + shared + "\n",
        dry_run=dry_run,
        reason="opencode overlay + shared rules",
    )


def link_ego_skill(*, dry_run: bool) -> None:
    source = HOME / ".local" / "share" / "ego" / "ego-skills"
    if not source.exists():
        return
    for target in (
        HOME / ".config" / "opencode" / "skills" / "ego-browser",
    ):
        if target.is_symlink():
            dest = os.readlink(target)
            if ".agents" in dest or ".codex" in dest or ".claude" in dest:
                print(f"relink {target} -> {source} (was {dest})")
                if not dry_run:
                    target.unlink()
        replace_with_link(target, source, dry_run=dry_run)


def ensure_git_repo(url: str, dest: Path, *, dry_run: bool) -> bool:
    if (dest / ".git").exists():
        return True
    if dest.exists():
        print(f"skip {dest}: exists but is not a git checkout")
        return False
    print(f"clone {url} -> {dest}")
    if dry_run:
        return True
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run(["git", "clone", "--depth", "1", url, str(dest)], check=True)
    except subprocess.CalledProcessError as exc:
        print(f"skip clone {url}: {exc}")
        return False
    return True


def claude_bin() -> str | None:
    path = shutil.which("claude")
    return path


def apply_claude_plugins(*, dry_run: bool) -> None:
    claude = claude_bin()
    if not claude:
        print("skip claude plugins: claude CLI not on PATH")
        return
    for source, plugin in CLAUDE_PLUGINS:
        print(f"claude plugin marketplace add {source}")
        if not dry_run:
            result = subprocess.run(
                [claude, "plugin", "marketplace", "add", source],
                capture_output=True,
                text=True,
            )
            combined = f"{result.stdout}\n{result.stderr}".lower()
            if result.returncode != 0 and "already" not in combined:
                print(f"skip marketplace {source}: {result.stderr.strip() or result.stdout.strip()}")
                continue
        print(f"claude plugin install {plugin}")
        if dry_run:
            continue
        result = subprocess.run(
            [claude, "plugin", "install", plugin, "-s", "user", "-y"],
            capture_output=True,
            text=True,
        )
        combined = f"{result.stdout}\n{result.stderr}".lower()
        if result.returncode != 0 and "already" not in combined:
            print(f"skip plugin {plugin}: {result.stderr.strip() or result.stdout.strip()}")


def apply_opencode_adhd(*, dry_run: bool) -> None:
    if not ensure_git_repo(ADHD_REPO, ADHD_DIR, dry_run=dry_run):
        return
    if not dry_run and not ADHD_PLUGIN.exists():
        print(f"skip adhd plugin: {ADHD_PLUGIN} missing")
        return
    if ADHD_ALWAYS.exists() or ADHD_ALWAYS.is_symlink():
        return
    print(f"create {ADHD_ALWAYS}")
    if dry_run:
        return
    ADHD_ALWAYS.parent.mkdir(parents=True, exist_ok=True)
    ADHD_ALWAYS.write_text("")


def apply_links(*, dry_run: bool) -> None:
    for source, target in LINKS:
        replace_with_link(target, source, dry_run=dry_run)
    chmod_executable(HOME / ".claude" / "hooks" / "cbm-session-reminder", dry_run=dry_run)
    chmod_executable(HOME / ".claude" / "hooks" / "cbm-subagent-reminder", dry_run=dry_run)
    chmod_executable(HOME / ".claude" / "hooks" / "cbm-code-discovery-gate", dry_run=dry_run)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    for source, target in COPY_IF_MISSING:
        copy_if_missing(source, target, dry_run=args.dry_run)
    apply_links(dry_run=args.dry_run)
    write_harness_agents(dry_run=args.dry_run)
    link_ego_skill(dry_run=args.dry_run)
    apply_opencode_adhd(dry_run=args.dry_run)
    apply_json_merges(dry_run=args.dry_run)
    apply_claude_plugins(dry_run=args.dry_run)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
