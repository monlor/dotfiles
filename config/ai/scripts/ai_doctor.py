#!/usr/bin/env python3

from __future__ import annotations

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


def expand(path: str) -> Path:
    return Path(os.path.expanduser(path))


def check(condition: bool, ok: str, fail: str, errors: list[str]) -> None:
    if condition:
        print(f"OK   {ok}")
    else:
        print(f"FAIL {fail}")
        errors.append(fail)


def registry() -> dict:
    return load_json(AI_ROOT / "registry.json")


def generated_manifest() -> dict:
    return load_json(GENERATED_ROOT / "manifest.json")


def enabled_tools(reg: dict) -> dict[str, dict]:
    return {
        name: config
        for name, config in reg["tools"].items()
        if config.get("enabled", True)
    }


def rtk_config(reg: dict) -> dict:
    return reg.get("rtk", {})


def server_commands() -> set[str]:
    commands = set()
    for server in load_json(AI_ROOT / "mcp" / "servers.json")["servers"]:
        commands.add(server["command"])
    return commands


def enabled_rtk_integrations(reg: dict) -> dict[str, dict]:
    rtk = rtk_config(reg)
    if not rtk.get("enabled", False):
        return {}

    tools = enabled_tools(reg)
    integrations: dict[str, dict] = {}
    for name, config in rtk.get("integrations", {}).items():
        if not config.get("enabled", True):
            continue
        tool_name = config.get("tool")
        if tool_name and tool_name not in tools:
            continue
        integrations[name] = config
    return integrations


def rtk_show_args(name: str, integration: dict) -> list[str] | None:
    mode = integration.get("mode")
    if mode == "wrapper":
        return None

    tool_name = integration.get("tool") or name
    if tool_name == "claude":
        return []
    if tool_name == "codex":
        return ["--codex"]
    if tool_name == "opencode":
        return ["--opencode"]
    return None


def rtk_integration_healthy(name: str, output: str) -> bool:
    checks = {
        "claude": [
            "Hook: not found",
            "RTK hook not configured",
            "RTK.md: not found",
        ],
        "codex": [
            "Global RTK.md: not found",
            "Global AGENTS.md: exists but rtk not configured",
        ],
        "opencode": [
            "OpenCode: plugin not found",
        ],
    }
    return not any(marker in output for marker in checks.get(name, []))


def check_rtk_integrations(reg: dict, errors: list[str]) -> None:
    rtk = rtk_config(reg)
    if not rtk.get("enabled", False):
        return

    rtk_bin = rtk.get("bin", "rtk")
    rtk_path = shutil.which(rtk_bin)
    if rtk_path is None:
        return

    for name, integration in enabled_rtk_integrations(reg).items():
        show_args = rtk_show_args(name, integration)
        if show_args is None:
            continue

        result = subprocess.run(
            [rtk_path, "init", "--show", *show_args],
            capture_output=True,
            text=True,
        )
        output = (result.stdout or "") + (result.stderr or "")
        check(
            result.returncode == 0 and rtk_integration_healthy(name, output),
            f"rtk integration '{name}' is installed",
            f"rtk integration '{name}' is not installed correctly",
            errors,
        )


def read_tool_servers(path: Path, config_format: str, server_key: str) -> dict:
    if not path.exists():
        return {}
    if config_format in ("toml",):
        return tomllib.loads(path.read_text()).get(server_key, {})
    if config_format in ("json", "json-merge"):
        return load_json(path).get(server_key, {})
    raise ValueError(f"Unsupported config format: {config_format}")


def shared_skill_names() -> set[str]:
    manifest = expand("~/.codex/skills/.ai-shared-skills.json")
    if manifest.exists():
        return set(load_json(manifest).get("managed", []))

    result = set()
    for path in (AI_ROOT / "skills").iterdir():
        if path.is_dir() and (path / "SKILL.md").is_file():
            result.add(path.name)
    return result


def check_tool_assets(tool: str, tool_config: dict, errors: list[str]) -> None:
    skills_path = tool_config.get("skills_path")
    if skills_path:
        skill_root = expand(skills_path)
        check(skill_root.exists(), f"{tool} skill dir exists", f"{tool} skill dir missing", errors)
        if tool_config.get("skills_mode", "links") == "links":
            expected = shared_skill_names()
            present = {path.name for path in skill_root.iterdir()} if skill_root.exists() else set()
            check(
                expected.issubset(present),
                f"{tool} shared skills are linked",
                f"{tool} is missing one or more shared skills",
                errors,
            )

    prompts_path = tool_config.get("prompts_path")
    if prompts_path:
        prompt_root = expand(prompts_path)
        check(prompt_root.exists(), f"{tool} prompt dir exists", f"{tool} prompt dir missing", errors)


def check_external_skill_sources(reg: dict, errors: list[str]) -> None:
    for source in reg.get("external_skill_sources", []):
        source_root = expand(source["path"])
        if source_root.exists():
            check(
                True,
                f"external skill source '{source['id']}' exists",
                f"external skill source '{source['id']}' missing at {source_root}",
                errors,
            )


def main() -> int:
    errors: list[str] = []
    reg = registry()
    tools = enabled_tools(reg)
    manifest_path = GENERATED_ROOT / "manifest.json"
    manifest_exists = manifest_path.exists()

    check((AI_ROOT / "registry.json").exists(), "registry.json exists", "registry.json missing", errors)
    check((AI_ROOT / "mcp" / "servers.json").exists(), "servers.json exists", "servers.json missing", errors)
    check(GENERATED_ROOT.exists(), "generated directory exists", "generated directory missing", errors)
    check(manifest_exists, "manifest.json exists", "manifest.json missing; run ai-sync", errors)
    if rtk_config(reg).get("enabled", False):
        check(
            (GENERATED_ROOT / "rtk.config.json").exists(),
            "rtk.config.json exists",
            "rtk.config.json missing; run ai-sync",
            errors,
        )

    for command in sorted(server_commands()):
        check(shutil.which(command) is not None, f"{command} is available", f"{command} is not on PATH", errors)
    if rtk_config(reg).get("enabled", False):
        rtk_bin = rtk_config(reg).get("bin", "rtk")
        check(
            shutil.which(rtk_bin) is not None,
            f"{rtk_bin} is available",
            f"{rtk_bin} is not on PATH",
            errors,
        )

    manifest = generated_manifest() if manifest_exists else None
    managed = set(manifest.get("managed_server_ids", [])) if manifest else set(reg.get("managed_server_ids", []))

    for tool, tool_config in tools.items():
        config_path = expand(tool_config["config_path"])
        tool_servers = read_tool_servers(config_path, tool_config["config_format"], tool_config["server_key"])
        check(bool(tool_servers), f"{tool} MCP config present", f"{tool} MCP config missing", errors)
        check(
            managed.issubset(set(tool_servers.keys())),
            f"{tool} includes managed servers",
            f"{tool} is missing one or more managed servers",
            errors,
        )
        check_tool_assets(tool, tool_config, errors)

    profile = manifest.get("profile", reg["default_profile"]) if manifest else reg["default_profile"]
    check(profile == reg["default_profile"], f"default profile is active ({profile})", f"active profile differs from default ({profile})", errors)

    for value in reg.get("paths", {}).values():
        path = expand(value)
        check(path.exists(), f"managed path exists: {path}", f"managed path missing: {path}", errors)

    if rtk_config(reg).get("enabled", False):
        rtk_path = expand(rtk_config(reg)["config_path"])
        check(
            rtk_path.exists(),
            f"rtk config exists: {rtk_path}",
            f"rtk config missing: {rtk_path}",
            errors,
        )
        if manifest:
            check(
                set(enabled_rtk_integrations(reg)).issubset(set(manifest.get("rtk_integrations", []))),
                "rtk integrations match manifest",
                "rtk integrations missing from manifest",
                errors,
            )
        check_rtk_integrations(reg, errors)

    check_external_skill_sources(reg, errors)

    if errors:
        print(f"\nDoctor found {len(errors)} issue(s).")
        return 1
    print("\nDoctor checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
