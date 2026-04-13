# RTK Integration

This directory documents the optional RTK integration layer for local AI tools.

Goals:

- add RTK without replacing existing Codex / Claude / OpenCode / OpenClaw configs
- keep the current AI control plane (`config/ai`) as the source of truth
- make RTK usage opt-in through shell helpers and environment variables

## What this integration does

- installs the `rtk` CLI in development mode
- exposes shell helpers for common RTK workflows
- keeps Codex / Claude / OpenCode / OpenClaw usable without RTK
- avoids editing generated AI config artifacts directly

## What this integration does not do

- it does **not** force all AI tool invocations through RTK
- it does **not** assume OpenClaw has a native `rtk init --openclaw` path
- it does **not** overwrite private auth or local UI preferences

## Recommended workflow

After `rtk` is installed, initialize the tools you want manually:

```bash
rtk init -g
rtk init -g --claude
# if supported by your installed rtk version:
# rtk init -g --opencode
```

For OpenClaw, treat RTK as a plugin/wrapper-style integration rather than a first-class
`rtk init` target unless your installed RTK version explicitly adds native support.

## Shell helpers

The zsh AI helpers expose these convenience commands:

- `rtk-check` — show RTK version/help
- `rtk-codex <args...>` — run Codex through RTK
- `rtk-claude <args...>` — run Claude through RTK
- `rtk-opencode <args...>` — run OpenCode through RTK
- `rtk-openclaw <args...>` — show a reminder for OpenClaw plugin-style setup

These helpers are intentionally light-touch: they add an ergonomic layer without hijacking
existing tool defaults.
