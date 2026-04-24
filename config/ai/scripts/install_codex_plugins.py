#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys


OPENAI_PLUGINS_REPO = "https://github.com/openai/plugins"


def run(command: list[str]) -> str:
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    return result.stdout.strip()


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Install and enable Codex plugins from openai/plugins.")
    parser.add_argument("plugins", nargs="+", help="Plugin names from the openai/plugins marketplace")
    return parser.parse_args(argv)


def ensure_marketplace_checkout(plugin_names: list[str]) -> tuple[Path, str]:
    vendor_repo = Path.home() / ".codex" / "vendor_imports" / "openai-plugins-marketplace"
    sparse_paths = [f"plugins/{name}" for name in plugin_names]

    if vendor_repo.exists():
        subprocess.run(
            ["git", "-C", str(vendor_repo), "fetch", "--depth", "1", "origin", "main"],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(vendor_repo), "checkout", "FETCH_HEAD"],
            check=True,
        )
    else:
        vendor_repo.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                "git",
                "clone",
                "--depth",
                "1",
                "--filter=blob:none",
                "--sparse",
                OPENAI_PLUGINS_REPO,
                str(vendor_repo),
            ],
            check=True,
        )

    subprocess.run(
        ["git", "-C", str(vendor_repo), "sparse-checkout", "set", *sparse_paths],
        check=True,
    )
    commit = run(["git", "-C", str(vendor_repo), "rev-parse", "HEAD"])
    return vendor_repo, commit


def copy_plugin_cache(vendor_repo: Path, commit: str, plugin_names: list[str]) -> None:
    cache_root = Path.home() / ".codex" / "plugins" / "cache" / "openai-curated"

    for plugin_name in plugin_names:
        source = vendor_repo / "plugins" / plugin_name
        if not source.exists():
            raise FileNotFoundError(f"Plugin not found in openai/plugins: {plugin_name}")

        destination = cache_root / plugin_name / commit
        if destination.exists():
            continue

        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(source, destination)


def update_codex_config(plugin_names: list[str]) -> None:
    config_path = Path.home() / ".codex" / "config.toml"
    if not config_path.exists():
        return

    content = config_path.read_text()
    for plugin_name in plugin_names:
        pattern = (
            r'^\[plugins\."'
            + re.escape(plugin_name)
            + r'@openai-curated"\]\n(?:.*\n)*?(?=^\[|\Z)'
        )
        content = re.sub(pattern, "", content, flags=re.MULTILINE)

    content = content.rstrip() + "\n\n"
    for plugin_name in plugin_names:
        content += f'[plugins."{plugin_name}@openai-curated"]\n'
        content += "enabled = true\n\n"

    config_path.write_text(re.sub(r"\n{3,}", "\n\n", content).rstrip() + "\n")


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    plugin_names = list(dict.fromkeys(args.plugins))
    vendor_repo, commit = ensure_marketplace_checkout(plugin_names)
    copy_plugin_cache(vendor_repo, commit, plugin_names)
    update_codex_config(plugin_names)
    print(f"Configured Codex plugins: {', '.join(plugin_names)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
