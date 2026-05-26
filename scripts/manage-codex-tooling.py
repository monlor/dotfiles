#!/usr/bin/env python3

from __future__ import annotations

import argparse
import datetime as dt
import json
import platform
from pathlib import Path
import re
import shutil
import subprocess
import sys


REPO_ROOT = Path(__file__).resolve().parent.parent
CODEX_DIR = Path.home() / ".codex"
CONFIG_PATH = CODEX_DIR / "config.toml"
AGENTS_PATH = CODEX_DIR / "AGENTS.md"
BASELINE_CONFIG_PATH = REPO_ROOT / "config" / "ai" / "codex" / "config.toml"
BASELINE_AGENTS_PATH = REPO_ROOT / "config" / "ai" / "codex" / "AGENTS.md"
RTK_RULES_PATH = CODEX_DIR / "RTK.md"
CODEGRAPH_RULES_PATH = CODEX_DIR / "CODEGRAPH.md"
CAVEMAN_RULES_PATH = CODEX_DIR / "CAVEMAN.md"
STATE_PATH = CODEX_DIR / ".codex-tooling-state.json"

AGENTS_BEGIN = "<!-- BEGIN MANAGED CODEX TOOLING -->"
AGENTS_END = "<!-- END MANAGED CODEX TOOLING -->"
CONFIG_BEGIN = "# BEGIN MANAGED CODEX TOOLING"
CONFIG_END = "# END MANAGED CODEX TOOLING"

BACKED_UP: set[Path] = set()
CAVEMAN_SKILLS = [
    "cavecrew",
    "caveman",
    "caveman-commit",
    "caveman-compress",
    "caveman-help",
    "caveman-review",
    "caveman-stats",
]


def load_state() -> dict[str, object]:
    if not STATE_PATH.exists():
        return {}
    return json.loads(STATE_PATH.read_text())


def save_state(state: dict[str, object], *, dry_run: bool) -> None:
    write_text(STATE_PATH, json.dumps(state, indent=2, sort_keys=True) + "\n", dry_run=dry_run)


def ensure_macos() -> None:
    if platform.system() != "Darwin":
        raise RuntimeError("This helper currently supports macOS only.")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install or remove Codex codegraph/rtk/caveman tooling."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print actions without changing files or installing packages.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("install", help="Install and configure the tooling.")
    subparsers.add_parser("uninstall", help="Remove the tooling managed by this script.")
    subparsers.add_parser("status", help="Show current tooling status.")
    return parser.parse_args(argv)


def run(command: list[str], *, dry_run: bool, check: bool = True) -> subprocess.CompletedProcess[str]:
    print("$", " ".join(command))
    if dry_run:
        return subprocess.CompletedProcess(command, 0, "", "")
    return subprocess.run(command, check=check, text=True, capture_output=True)


def backup_file(path: Path, *, dry_run: bool) -> None:
    if path in BACKED_UP or not path.exists():
        return

    timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = path.with_name(f"{path.name}.bak.codex-tooling-{timestamp}")
    print(f"backup {path} -> {backup_path}")
    if not dry_run:
        shutil.copy2(path, backup_path)
    BACKED_UP.add(path)


def ensure_file(path: Path, source: Path, *, dry_run: bool) -> None:
    if path.exists():
        return

    print(f"create {path} from {source}")
    if dry_run:
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, path)


def ensure_codex_baseline(*, dry_run: bool) -> None:
    if dry_run:
        print(f"ensure directory {CODEX_DIR}")
    else:
        CODEX_DIR.mkdir(parents=True, exist_ok=True)

    ensure_file(CONFIG_PATH, BASELINE_CONFIG_PATH, dry_run=dry_run)
    ensure_file(AGENTS_PATH, BASELINE_AGENTS_PATH, dry_run=dry_run)


def strip_block(text: str, begin: str, end: str) -> str:
    pattern = re.compile(
        rf"\n?{re.escape(begin)}\n.*?\n{re.escape(end)}\n?",
        re.DOTALL,
    )
    return re.sub(pattern, "\n", text).strip() + "\n"


def upsert_block(text: str, begin: str, end: str, body: str) -> str:
    cleaned = strip_block(text, begin, end).rstrip()
    block = f"{begin}\n{body.rstrip()}\n{end}\n"
    if cleaned:
        return f"{cleaned}\n\n{block}"
    return block


def write_text(path: Path, content: str, *, dry_run: bool) -> None:
    print(f"write {path}")
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def remove_file(path: Path, *, dry_run: bool) -> None:
    if not path.exists():
        return
    print(f"remove {path}")
    if not dry_run:
        path.unlink()


def ensure_rtk_installed(state: dict[str, object], *, dry_run: bool) -> None:
    if shutil.which("rtk"):
        print("rtk already installed")
        state["rtk_install_method"] = "preexisting"
        return
    if not shutil.which("brew"):
        raise RuntimeError("rtk is missing and Homebrew is not available.")
    run(["brew", "install", "rtk"], dry_run=dry_run)
    state["rtk_install_method"] = "brew"


def ensure_codegraph_installed(state: dict[str, object], *, dry_run: bool) -> None:
    if shutil.which("codegraph"):
        print("codegraph already installed")
        state["codegraph_install_method"] = "preexisting"
        return
    if not shutil.which("npm"):
        raise RuntimeError("codegraph is missing and npm is not available.")
    run(["npm", "install", "-g", "@colbymchenry/codegraph"], dry_run=dry_run)
    state["codegraph_install_method"] = "npm"


def uninstall_package(
    state: dict[str, object],
    state_key: str,
    expected_method: str,
    uninstall_command: list[str],
    *,
    dry_run: bool,
) -> None:
    install_method = state.get(state_key)
    if install_method != expected_method:
        print(f"skip uninstall for {state_key}: state={install_method!r}")
        return
    if expected_method == "brew":
        result = subprocess.run(
            ["brew", "list", "--versions", uninstall_command[-1]],
            check=False,
            text=True,
            capture_output=True,
        )
        if result.returncode != 0 or not result.stdout.strip():
            print(f"skip uninstall for {state_key}: brew package missing")
            return
    if expected_method == "npm":
        result = subprocess.run(
            ["npm", "list", "-g", "--depth=0", uninstall_command[-1]],
            check=False,
            text=True,
            capture_output=True,
        )
        if result.returncode != 0:
            print(f"skip uninstall for {state_key}: npm package missing")
            return
    run(uninstall_command, dry_run=dry_run)


def install_caveman_skills(*, dry_run: bool) -> None:
    if not shutil.which("npx"):
        raise RuntimeError("npx is required to install caveman Codex skills.")
    run(
        ["npx", "-y", "skills", "add", "JuliusBrussee/caveman", "-a", "codex", "-g", "-y"],
        dry_run=dry_run,
    )


def uninstall_caveman_skills(*, dry_run: bool) -> None:
    if not shutil.which("npx"):
        print("npx not available; skip caveman skill removal")
        return
    run(
        ["npx", "-y", "skills", "remove", "-g", "-a", "codex", "-y", *CAVEMAN_SKILLS],
        dry_run=dry_run,
        check=False,
    )


def codegraph_rules_text() -> str:
    return """# CodeGraph for Codex

Use CodeGraph when the current project already has a `.codegraph/` directory.

- Prefer CodeGraph MCP tools for codebase structure, symbol lookup, callers/callees, impact, and task context.
- If the user asks to enable CodeGraph for a repo that is not initialized yet, run `codegraph init -i` in that repo.
- After large file changes, run `codegraph sync` if the graph looks stale.
"""


def caveman_rules_text() -> str:
    return """# Caveman Mode for Codex

Default to terse technical output.

- Use compact technical fragments.
- No filler or cheerleading.
- Keep all required risk, blockers, commands, and verification details.
- Expand only when the user asks for more detail or when brevity would hide important risk.
"""


def agents_block() -> str:
    return "\n".join(
        [
            "@/Users/monlor/.codex/RTK.md",
            "@/Users/monlor/.codex/CODEGRAPH.md",
            "@/Users/monlor/.codex/CAVEMAN.md",
        ]
    )


def codegraph_config_block() -> str:
    return """[mcp_servers.codegraph]
command = "codegraph"
args = ["serve", "--mcp"]
startup_timeout_sec = 120"""


def has_external_codegraph_config(content: str) -> bool:
    unmanaged = strip_block(content, CONFIG_BEGIN, CONFIG_END)
    pattern = re.compile(r"^\[mcp_servers\.codegraph\]\n(?:.*\n)*?(?=^\[|\Z)", re.MULTILINE)
    return bool(pattern.search(unmanaged))


def patch_agents(*, dry_run: bool) -> None:
    backup_file(AGENTS_PATH, dry_run=dry_run)
    content = AGENTS_PATH.read_text() if AGENTS_PATH.exists() else ""
    content = re.sub(r"^@/Users/monlor/\.codex/(RTK|CODEGRAPH|CAVEMAN)\.md\s*$\n?", "", content, flags=re.MULTILINE)
    content = upsert_block(content, AGENTS_BEGIN, AGENTS_END, agents_block())
    write_text(AGENTS_PATH, content, dry_run=dry_run)


def unpatch_agents(*, dry_run: bool) -> None:
    if not AGENTS_PATH.exists():
        return
    backup_file(AGENTS_PATH, dry_run=dry_run)
    content = AGENTS_PATH.read_text()
    content = strip_block(content, AGENTS_BEGIN, AGENTS_END)
    content = re.sub(r"^@/Users/monlor/\.codex/(RTK|CODEGRAPH|CAVEMAN)\.md\s*$\n?", "", content, flags=re.MULTILINE)
    write_text(AGENTS_PATH, content, dry_run=dry_run)


def patch_config(*, dry_run: bool) -> None:
    backup_file(CONFIG_PATH, dry_run=dry_run)
    content = CONFIG_PATH.read_text() if CONFIG_PATH.exists() else ""
    if has_external_codegraph_config(content):
        print("preserve existing external [mcp_servers.codegraph] config")
        content = strip_block(content, CONFIG_BEGIN, CONFIG_END)
        write_text(CONFIG_PATH, content, dry_run=dry_run)
        return
    content = upsert_block(content, CONFIG_BEGIN, CONFIG_END, codegraph_config_block())
    write_text(CONFIG_PATH, content, dry_run=dry_run)


def unpatch_config(*, dry_run: bool) -> None:
    if not CONFIG_PATH.exists():
        return
    backup_file(CONFIG_PATH, dry_run=dry_run)
    content = CONFIG_PATH.read_text()
    content = strip_block(content, CONFIG_BEGIN, CONFIG_END)
    write_text(CONFIG_PATH, content, dry_run=dry_run)


def write_rule_files(*, dry_run: bool) -> None:
    write_text(CODEGRAPH_RULES_PATH, codegraph_rules_text(), dry_run=dry_run)
    write_text(CAVEMAN_RULES_PATH, caveman_rules_text(), dry_run=dry_run)

    if shutil.which("rtk"):
        run(["rtk", "init", "--codex", "--global"], dry_run=dry_run, check=False)
    elif dry_run:
        print("$ rtk init --codex --global")
    else:
        raise RuntimeError("rtk is required before writing RTK.md.")


def remove_rule_files(*, dry_run: bool) -> None:
    remove_file(CODEGRAPH_RULES_PATH, dry_run=dry_run)
    remove_file(CAVEMAN_RULES_PATH, dry_run=dry_run)
    remove_file(RTK_RULES_PATH, dry_run=dry_run)


def get_installed_caveman_skills() -> set[str]:
    if not shutil.which("npx"):
        return set()

    result = subprocess.run(
        ["npx", "-y", "skills", "ls", "-g", "--json"],
        check=False,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        return set()

    try:
        rows = json.loads(result.stdout)
    except json.JSONDecodeError:
        return set()

    return {row["name"] for row in rows if isinstance(row, dict) and "name" in row}


def print_status() -> int:
    state = load_state()
    print("Executables")
    for name in ("rtk", "codegraph", "npx"):
        path = shutil.which(name)
        print(f"- {name}: {path or 'missing'}")

    print("\nCodex files")
    for path in (
        CONFIG_PATH,
        AGENTS_PATH,
        RTK_RULES_PATH,
        CODEGRAPH_RULES_PATH,
        CAVEMAN_RULES_PATH,
    ):
        print(f"- {path}: {'present' if path.exists() else 'missing'}")

    print("\nManaged config")
    if CONFIG_PATH.exists():
        print(f"- codegraph MCP block: {'yes' if CONFIG_BEGIN in CONFIG_PATH.read_text() else 'no'}")
        print(f"- external codegraph config: {'yes' if has_external_codegraph_config(CONFIG_PATH.read_text()) else 'no'}")
    else:
        print("- codegraph MCP block: no config")
        print("- external codegraph config: no config")

    if AGENTS_PATH.exists():
        print(f"- AGENTS managed block: {'yes' if AGENTS_BEGIN in AGENTS_PATH.read_text() else 'no'}")
    else:
        print("- AGENTS managed block: no AGENTS")

    print("\nInstall state")
    print(f"- rtk install method: {state.get('rtk_install_method', 'unknown')}")
    print(f"- codegraph install method: {state.get('codegraph_install_method', 'unknown')}")

    print("\nCaveman skills")
    installed_skills = get_installed_caveman_skills()
    for skill in CAVEMAN_SKILLS:
        print(f"- {skill}: {'present' if skill in installed_skills else 'missing'}")
    return 0


def install(*, dry_run: bool) -> int:
    ensure_macos()
    state = load_state()
    ensure_codex_baseline(dry_run=dry_run)
    ensure_rtk_installed(state, dry_run=dry_run)
    ensure_codegraph_installed(state, dry_run=dry_run)
    install_caveman_skills(dry_run=dry_run)
    write_rule_files(dry_run=dry_run)
    patch_agents(dry_run=dry_run)
    patch_config(dry_run=dry_run)
    save_state(state, dry_run=dry_run)
    return 0


def uninstall(*, dry_run: bool) -> int:
    ensure_macos()
    state = load_state()
    uninstall_caveman_skills(dry_run=dry_run)
    unpatch_agents(dry_run=dry_run)
    unpatch_config(dry_run=dry_run)
    remove_rule_files(dry_run=dry_run)
    uninstall_package(
        state,
        "codegraph_install_method",
        "npm",
        ["npm", "uninstall", "-g", "@colbymchenry/codegraph"],
        dry_run=dry_run,
    )
    uninstall_package(
        state,
        "rtk_install_method",
        "brew",
        ["brew", "uninstall", "rtk"],
        dry_run=dry_run,
    )
    remove_file(STATE_PATH, dry_run=dry_run)
    return 0


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        if args.command == "install":
            return install(dry_run=args.dry_run)
        if args.command == "uninstall":
            return uninstall(dry_run=args.dry_run)
        if args.command == "status":
            return print_status()
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
