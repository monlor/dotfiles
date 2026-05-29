---
name: sync-codex-dotfiles
description: Sync reusable Codex global configuration from ~/.codex into the dotfiles Codex config directory while filtering machine-local state. Use when the user asks to sync Codex config to dotfiles, update shared Codex settings, or avoid copying local project trust, credentials, sessions, caches, and runtime paths.
---

# Sync Codex Dotfiles

## Quick Start

Preview the sanitized sync first:

```bash
~/.dotfiles/config/ai/agents/skills/sync-codex-dotfiles/scripts/sync-codex-dotfiles.py
```

Apply only after reviewing the diff:

```bash
~/.dotfiles/config/ai/agents/skills/sync-codex-dotfiles/scripts/sync-codex-dotfiles.py --apply
```

## Workflow

1. Read `~/.codex/config.toml` and the existing dotfiles target at `~/.dotfiles/config/ai/codex/config.toml`.
2. Generate a sanitized config that keeps shared preferences, models, agents, features, plugins, profiles, MCP server definitions, and desktop-wide settings.
3. Exclude local or generated state:
   - `auth.json`, installation IDs, history, sessions, logs, sqlite state, caches, browser/computer-use runtime state
   - `[projects.*]` local folder trust authorizations
   - `[hooks.state.*]` trusted runtime hashes
   - `[desktop.open-in-target-preferences.perPath]` local path preferences
   - `[mcp_servers.node_repl*]` app/runtime paths
   - `[apps.*]`, `[notice.*]`, generated marketplace timestamps/revisions and local-source marketplaces
   - top-level `notify` paths
4. Sync allowlisted files/directories only:
   - `AGENTS.md`
   - `config.toml`
   - `agents/`
   - `keybindings.json`
   - `prompts/`
   - `git-hooks/`
5. Show a diff in dry-run mode. Use `--apply` to write.

## Notes

- Prefer editing the filter rules in `scripts/sync-codex-dotfiles.py` over copying the whole `~/.codex` directory.
- If a field contains an absolute local path, treat it as local by default unless it is intentionally portable.
- If Codex changes its config schema, run dry-run and inspect the diff before applying.
