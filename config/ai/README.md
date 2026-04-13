# AI Control Plane

This directory is the single source of truth for shared AI tooling across
Codex, Cursor, Gemini, and Claude Code.

It also contains optional integration notes for RTK under `rtk/`.

Layout:

- `registry.json`: top-level tool and profile settings
- `mcp/servers.json`: shared MCP server definitions
- `powers/*.json`: risk-tier profiles
- `skills/`: shared user skills
- `prompts/`: shared workflow prompts
- `generated/`: generated config artifacts
- `rtk/`: optional RTK integration notes and helpers
- `scripts/`: sync and diagnostic tools

`ai-sync` reads this directory and updates each tool's managed shared state
without overwriting private auth, history, or UI preferences.

Current status:

- `pinchtab` is configured in `mcp/servers.json` and propagated into the
  generated Codex, Claude, and Gemini MCP configs under `generated/`.
- `ai-doctor` verifies that the shared control plane is wired correctly and
  that required commands such as `pinchtab` and `npx` are available.
- The local plugin repo is only a helper checkout location. It is not required
  by the control plane itself. Shell helpers default `LOCAL_PLUGIN_REPO` to
  `$HOME/.code/plugins/compound-engineering-plugin`, and `gstack` external
  skills are discovered from `$HOME/.code/gstack` (cloned by `install.conf.yaml`).
  Both paths can be overridden locally when needed.
