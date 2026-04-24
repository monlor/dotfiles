#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Enable bundled Codex plugins in ~/.codex/config.toml."
    )
    parser.add_argument("plugins", nargs="+", help="Bundled plugin names to enable")
    return parser.parse_args(argv)


def update_codex_config(plugin_names: list[str]) -> None:
    config_path = Path.home() / ".codex" / "config.toml"
    if not config_path.exists():
        return

    content = config_path.read_text()
    for plugin_name in plugin_names:
        pattern = (
            r'^\[plugins\."'
            + re.escape(plugin_name)
            + r'@openai-bundled"\]\n(?:.*\n)*?(?=^\[|\Z)'
        )
        content = re.sub(pattern, "", content, flags=re.MULTILINE)

    content = content.rstrip() + "\n\n"
    for plugin_name in plugin_names:
        content += f'[plugins."{plugin_name}@openai-bundled"]\n'
        content += "enabled = true\n\n"

    config_path.write_text(re.sub(r"\n{3,}", "\n\n", content).rstrip() + "\n")


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    plugin_names = list(dict.fromkeys(args.plugins))
    update_codex_config(plugin_names)
    print(f"Enabled bundled Codex plugins: {', '.join(plugin_names)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
