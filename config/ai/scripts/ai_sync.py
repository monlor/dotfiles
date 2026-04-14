#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tomllib


ROOT = Path(__file__).resolve().parents[3]
AI_ROOT = ROOT / "config" / "ai"
GENERATED_ROOT = AI_ROOT / "generated"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text())


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def write_json(path: Path, payload: object) -> None:
    write_text(path, json.dumps(payload, indent=2, ensure_ascii=True) + "\n")


def expand_path(path: str) -> Path:
    return Path(os.path.expanduser(path))


def toml_key(key: str) -> str:
    safe = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
    if key and all(ch in safe for ch in key):
        return key
    return json.dumps(key)


def toml_value(value: object) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(item) for item in value) + "]"
    raise TypeError(f"Unsupported TOML value: {type(value)!r}")


def dump_toml(data: dict) -> str:
    lines: list[str] = []

    def emit_table(prefix: list[str], table: dict, is_array_item: bool = False) -> None:
        scalar_items: list[tuple[str, object]] = []
        child_items: list[tuple[str, dict]] = []
        array_table_items: list[tuple[str, list[dict]]] = []
        for key, value in table.items():
            if isinstance(value, dict):
                child_items.append((key, value))
            elif isinstance(value, list) and value and all(isinstance(item, dict) for item in value):
                array_table_items.append((key, value))
            else:
                scalar_items.append((key, value))

        if prefix and (scalar_items or child_items or array_table_items):
            table_name = ".".join(toml_key(part) for part in prefix)
            if is_array_item:
                lines.append(f"[[{table_name}]]")
            else:
                lines.append(f"[{table_name}]")
        for key, value in scalar_items:
            lines.append(f"{toml_key(key)} = {toml_value(value)}")
        if prefix and (scalar_items or child_items or array_table_items):
            lines.append("")
        for key, value in child_items:
            if value:
                emit_table(prefix + [key], value)
        for key, value in array_table_items:
            for item in value:
                emit_table(prefix + [key], item, is_array_item=True)

    root_scalars: dict[str, object] = {}
    root_tables: dict[str, dict] = {}
    root_array_tables: dict[str, list[dict]] = {}
    for key, value in data.items():
        if isinstance(value, dict):
            root_tables[key] = value
        elif isinstance(value, list) and value and all(isinstance(item, dict) for item in value):
            root_array_tables[key] = value
        else:
            root_scalars[key] = value
    for key, value in root_scalars.items():
        lines.append(f"{toml_key(key)} = {toml_value(value)}")
    if root_scalars and (root_tables or root_array_tables):
        lines.append("")
    for key, value in root_tables.items():
        emit_table([key], value)
    for key, value in root_array_tables.items():
        for item in value:
            emit_table([key], item, is_array_item=True)
    return "\n".join(lines).rstrip() + "\n"


def load_registry() -> dict:
    return load_json(AI_ROOT / "registry.json")


def load_servers() -> list[dict]:
    payload = load_json(AI_ROOT / "mcp" / "servers.json")
    return payload["servers"]


def load_profile(name: str) -> dict:
    return load_json(AI_ROOT / "powers" / f"{name}.json")


def enabled_tools(registry: dict) -> dict[str, dict]:
    return {
        name: config
        for name, config in registry["tools"].items()
        if config.get("enabled", True)
    }


def rtk_config(registry: dict) -> dict:
    return registry.get("rtk", {})


def enabled_rtk_integrations(registry: dict) -> dict[str, dict]:
    rtk = rtk_config(registry)
    if not rtk.get("enabled", False):
        return {}

    tools = enabled_tools(registry)
    integrations: dict[str, dict] = {}
    for name, integration in rtk.get("integrations", {}).items():
        if not integration.get("enabled", True):
            continue

        payload = dict(integration)
        tool_name = payload.get("tool")
        if tool_name:
            if tool_name not in tools:
                continue
            tool_config = tools[tool_name]
            payload["tool"] = tool_name
            payload["tool_config_path"] = tool_config.get("config_path")
            if "settings_path" in tool_config:
                payload["tool_settings_path"] = tool_config["settings_path"]
            if "skills_path" in tool_config:
                payload["skills_path"] = tool_config["skills_path"]
            if "prompts_path" in tool_config:
                payload["prompts_path"] = tool_config["prompts_path"]
        integrations[name] = payload
    return integrations


def active_servers(tool: str, profile: str) -> dict[str, dict]:
    allowed_tiers = set(load_profile(profile)["allowed_tiers"])
    selected: dict[str, dict] = {}
    for server in load_servers():
        if tool not in server["enabled_for"]:
            continue
        if server["risk_tier"] not in allowed_tiers:
            continue
        merged = {
            "command": server["command"],
            "args": list(server.get("args", [])),
        }
        env = dict(server.get("env", {}))
        if env:
            merged["env"] = env
        override = server.get("tool_overrides", {}).get(tool, {})
        if "type" in override:
            merged["type"] = override["type"]
        if "command" in override:
            merged["command"] = override["command"]
        if "args" in override:
            merged["args"] = list(override["args"])
        if "env" in override:
            merged_env = dict(merged.get("env", {}))
            merged_env.update(override["env"])
            if merged_env:
                merged["env"] = merged_env
        if tool == "opencode":
            merged = {
                "type": "local",
                "command": [merged["command"]] + list(merged.get("args", [])),
            }
            env = merged.get("env")
            if env:
                merged["environment"] = env
        elif tool == "claude":
            merged = {
                "type": "stdio",
                "command": merged["command"],
                "args": merged["args"],
                "env": merged.get("env", {}),
            }
        selected[server["id"]] = merged
    return selected


def managed_server_ids() -> set[str]:
    return set(load_registry()["managed_server_ids"])


def retired_server_ids() -> set[str]:
    return set(load_registry().get("retired_server_ids", []))


def merge_managed_servers(existing: dict[str, dict], shared: dict[str, dict]) -> dict[str, dict]:
    excluded = managed_server_ids() | retired_server_ids()
    merged = {key: value for key, value in existing.items() if key not in excluded}
    for key, value in shared.items():
        merged[key] = value
    return merged


def prune_retired_metadata(value: object) -> object:
    retired = retired_server_ids()
    if isinstance(value, dict):
        pruned: dict[object, object] = {}
        for key, item in value.items():
            cleaned = prune_retired_metadata(item)
            if key == "disabledMcpServers" and isinstance(cleaned, list):
                cleaned = [entry for entry in cleaned if entry not in retired]
            pruned[key] = cleaned
        return pruned
    if isinstance(value, list):
        return [prune_retired_metadata(item) for item in value]
    return value


def write_generated(profile: str, registry: dict) -> None:
    payloads = {tool: active_servers(tool, profile) for tool in enabled_tools(registry)}
    rtk = rtk_config(registry)
    rtk_integrations = enabled_rtk_integrations(registry)

    write_text(
        GENERATED_ROOT / "codex.toml",
        dump_toml({"mcp_servers": payloads.get("codex", {})}),
    )
    write_json(GENERATED_ROOT / "gemini.settings.json", {"mcpServers": payloads.get("gemini", {})})
    write_json(GENERATED_ROOT / "claude.json", {"mcpServers": payloads.get("claude", {})})
    if rtk.get("enabled", False):
        write_json(
            GENERATED_ROOT / "rtk.config.json",
            {
                "profile": profile,
                "bin": rtk.get("bin", "rtk"),
                "integrations": rtk_integrations,
            },
        )
    write_json(
        GENERATED_ROOT / "manifest.json",
        {
            "profile": profile,
            "managed_server_ids": sorted(managed_server_ids()),
            "retired_server_ids": sorted(retired_server_ids()),
            "skills": discover_skill_names(),
            "prompts": discover_prompt_names(),
            "tools": sorted(enabled_tools(registry)),
            "rtk_enabled": rtk.get("enabled", False),
            "rtk_integrations": sorted(rtk_integrations),
            "external_skill_sources": [
                source["id"] for source in registry.get("external_skill_sources", [])
            ],
        },
    )


def deep_merge(base: dict, overlay: dict) -> dict:
    """Recursively merge overlay into base, preferring overlay values."""
    result = dict(base)
    for key, val in overlay.items():
        if key in result and isinstance(result[key], dict) and isinstance(val, dict):
            result[key] = deep_merge(result[key], val)
        else:
            result[key] = val
    return result


def read_tool_config(config_path: Path, config_format: str) -> dict:
    if not config_path.exists():
        return {}
    if config_format == "toml":
        return tomllib.loads(config_path.read_text())
    if config_format in ("json", "json-merge"):
        return prune_retired_metadata(load_json(config_path))
    raise ValueError(f"Unsupported config format: {config_format}")


def write_tool_config(config_path: Path, config_format: str, payload: dict) -> None:
    if config_format == "toml":
        write_text(config_path, dump_toml(payload))
        return
    if config_format in ("json", "json-merge"):
        if config_format == "json-merge" and config_path.exists():
            existing = load_json(config_path)
            payload = deep_merge(existing, payload)
        write_json(config_path, payload)
        return
    raise ValueError(f"Unsupported config format: {config_format}")


def sync_tool_servers(tool: str, tool_config: dict, profile: str) -> None:
    if "config_path" not in tool_config:
        return
    config_path = expand_path(tool_config["config_path"])
    config = read_tool_config(config_path, tool_config["config_format"])
    server_key = tool_config["server_key"]
    config[server_key] = merge_managed_servers(config.get(server_key, {}), active_servers(tool, profile))
    write_tool_config(config_path, tool_config["config_format"], config)


def sync_rtk_config(registry: dict, profile: str) -> None:
    rtk = rtk_config(registry)
    if not rtk.get("enabled", False):
        return

    config_path = rtk.get("config_path")
    if not config_path:
        return

    payload = {
        "profile": profile,
        "bin": rtk.get("bin", "rtk"),
        "integrations": enabled_rtk_integrations(registry),
    }
    write_json(expand_path(config_path), payload)


def rtk_init_args(name: str, integration: dict) -> list[str] | None:
    mode = integration.get("mode")
    if mode == "wrapper":
        return None

    tool_name = integration.get("tool") or name
    if tool_name == "claude":
        return ["--auto-patch"]
    if tool_name == "codex":
        return ["--codex"]
    if tool_name == "opencode":
        return ["--opencode"]
    return None


def normalize_codex_rtk_reference() -> None:
    agents_path = expand_path("~/.codex/AGENTS.md")
    if not agents_path.exists():
        return

    content = agents_path.read_text()
    normalized = content.replace(f"@{expand_path('~/.codex/RTK.md')}", "@RTK.md")
    if normalized != content:
        write_text(agents_path, normalized)


def sync_rtk_hooks(registry: dict) -> None:
    rtk = rtk_config(registry)
    if not rtk.get("enabled", False):
        return
    if not rtk.get("auto_init", True):
        return

    rtk_bin = rtk.get("bin", "rtk")
    rtk_path = shutil.which(rtk_bin)
    if rtk_path is None:
        print(f"Skipping RTK hook sync because '{rtk_bin}' is not on PATH.")
        return

    integrations = enabled_rtk_integrations(registry)
    for name, integration in integrations.items():
        init_args = rtk_init_args(name, integration)
        if init_args is None:
            continue

        command = [rtk_path, "init", "-g", *init_args]
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode != 0:
            if result.stdout:
                print(result.stdout.rstrip())
            if result.stderr:
                print(result.stderr.rstrip(), file=sys.stderr)
            raise RuntimeError(f"RTK init failed for integration '{name}'")
        if (integration.get("tool") or name) == "codex":
            normalize_codex_rtk_reference()
        print(f"Synced RTK integration '{name}'.")


def discover_skill_dirs() -> list[Path]:
    skills_root = AI_ROOT / "skills"
    result = []
    for path in sorted(skills_root.iterdir()):
        if not path.is_dir():
            continue
        if path.name.startswith("."):
            continue
        if (path / "SKILL.md").is_file():
            result.append(path)
    return result


def discover_skill_names() -> list[str]:
    return [path.name for path in discover_skill_dirs()]


def discover_prompt_paths() -> list[Path]:
    prompts_root = AI_ROOT / "prompts"
    return sorted(path for path in prompts_root.glob("*.md") if path.is_file())


def discover_prompt_names() -> list[str]:
    return [path.stem for path in discover_prompt_paths()]


def sync_links(src_items: list[Path], dest_root: Path, manifest_name: str) -> None:
    dest_root.mkdir(parents=True, exist_ok=True)
    manifest_path = dest_root / manifest_name
    previous = set()
    if manifest_path.exists():
        previous = set(load_json(manifest_path).get("managed", []))
    current_names = {path.name for path in src_items}

    for stale in sorted(previous - current_names):
        stale_path = dest_root / stale
        if stale_path.is_symlink() or stale_path.exists():
            if stale_path.is_dir() and not stale_path.is_symlink():
                shutil.rmtree(stale_path)
            else:
                stale_path.unlink()

    for src in src_items:
        dest = dest_root / src.name
        if dest.is_symlink():
            try:
                if dest.resolve() == src.resolve():
                    continue
            except FileNotFoundError:
                pass
            dest.unlink()
        elif dest.exists():
            # Replace existing dirs/files with symlinks so this tool stays in control
            if dest.is_dir() and not dest.is_symlink():
                shutil.rmtree(dest)
            else:
                dest.unlink()
        dest.symlink_to(src)

    write_json(manifest_path, {"managed": sorted(current_names)})


def discover_external_skill_dirs(source: dict) -> list[Path]:
    source_root = expand_path(source["path"])
    if not source_root.exists():
        return []
    result = []
    for path in sorted(source_root.iterdir()):
        if not path.is_dir():
            continue
        if path.name.startswith("."):
            continue
        if (path / "SKILL.md").is_file():
            result.append(path)
    return result


def relink_or_remove_legacy_entry(entry: Path, replacement: Path | None) -> None:
    if replacement and replacement.exists():
        if entry.is_symlink():
            entry.unlink()
        else:
            shutil.rmtree(entry)
        entry.symlink_to(replacement)
        return

    if entry.is_symlink():
        entry.unlink()
        return
    if entry.is_dir():
        shutil.rmtree(entry)


def cleanup_legacy_external_skills(dest_root: Path, source: dict) -> None:
    legacy_roots = tuple(source.get("legacy_roots", []))
    if not legacy_roots or not dest_root.exists():
        return

    source_root = expand_path(source["path"])
    for entry in dest_root.iterdir():
        replacement = source_root / entry.name

        if entry.is_symlink():
            try:
                target = os.readlink(entry)
            except OSError:
                continue
            if any(target.startswith(root) for root in legacy_roots):
                relink_or_remove_legacy_entry(entry, replacement)
            continue

        if not entry.is_dir():
            continue
        skill_file = entry / "SKILL.md"
        if not skill_file.is_symlink():
            continue
        try:
            target = os.readlink(skill_file)
        except OSError:
            continue
        if any(target.startswith(root) for root in legacy_roots):
            relink_or_remove_legacy_entry(entry, replacement if replacement.exists() else None)


def sync_tool_skills(tool: str, tool_config: dict, registry: dict) -> None:
    skills_path = tool_config.get("skills_path")
    if not skills_path:
        return

    skill_root = expand_path(skills_path)
    skill_mode = tool_config.get("skills_mode", "links")
    shared_skill_dirs = discover_skill_dirs()

    if skill_mode == "links":
        sync_links(shared_skill_dirs, skill_root, ".ai-shared-skills.json")
    elif skill_mode == "catalog":
        skill_root.mkdir(parents=True, exist_ok=True)
        external_names: list[str] = []
        for source in registry.get("external_skill_sources", []):
            if tool not in source.get("enabled_for", []):
                continue
            external_names.extend(p.name for p in discover_external_skill_dirs(source))
        write_json(skill_root / "catalog.json", {"skills": discover_skill_names() + external_names})
    else:
        raise ValueError(f"Unsupported skills_mode: {skill_mode}")

    for source in registry.get("external_skill_sources", []):
        if tool not in source.get("enabled_for", []):
            continue
        cleanup_legacy_external_skills(skill_root, source)
        external_dirs = discover_external_skill_dirs(source)
        if skill_mode == "links":
            manifest_name = f".ai-external-skills-{source['id']}.json"
            sync_links(external_dirs, skill_root, manifest_name)


def sync_tool_prompts(tool_config: dict) -> None:
    prompts_path = tool_config.get("prompts_path")
    if not prompts_path:
        return

    prompt_root = expand_path(prompts_path)
    prompt_mode = tool_config.get("prompts_mode", "links")
    prompt_paths = discover_prompt_paths()

    if prompt_mode == "links":
        sync_links(prompt_paths, prompt_root, ".ai-shared-prompts.json")
        return
    raise ValueError(f"Unsupported prompts_mode: {prompt_mode}")


def sync_skills_and_prompts(registry: dict) -> None:
    for tool, tool_config in enabled_tools(registry).items():
        sync_tool_skills(tool, tool_config, registry)
        sync_tool_prompts(tool_config)


def ensure_managed_paths(registry: dict) -> None:
    for value in registry.get("paths", {}).values():
        expand_path(value).mkdir(parents=True, exist_ok=True)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Sync shared AI config into local tool config.")
    parser.add_argument("--profile", help="Power profile to activate")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    registry = load_registry()
    profile = args.profile or registry["default_profile"]

    ensure_managed_paths(registry)
    write_generated(profile, registry)

    for tool, tool_config in enabled_tools(registry).items():
        sync_tool_servers(tool, tool_config, profile)
    sync_rtk_config(registry, profile)
    sync_rtk_hooks(registry)

    sync_skills_and_prompts(registry)

    print(f"Synced AI control plane with profile '{profile}'.")
    print(f"Generated artifacts in {GENERATED_ROOT}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
