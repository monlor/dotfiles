# RTK Integration

This directory documents the optional RTK integration layer for local AI tools.

Goals:

- add RTK without replacing existing Codex / Claude / OpenCode / OpenClaw configs
- keep the current AI control plane (`config/ai`) as the source of truth
- make RTK usage opt-in through shell helpers and environment variables
- make RTK integration targets configurable through `config/ai/registry.json`

## What this integration does

- installs the `rtk` CLI via Homebrew on macOS and `ghpkg rtk-ai/rtk` on Linux
- exposes shell helpers for common RTK workflows
- generates RTK config from the shared AI registry
- keeps Codex / Claude / OpenCode / OpenClaw usable without RTK
- avoids editing generated AI config artifacts directly

## What this integration does not do

- it does **not** force all AI tool invocations through RTK
- it does **not** assume OpenClaw has a native `rtk init --openclaw` path
- it does **not** overwrite private auth or local UI preferences

## Recommended workflow

After `rtk` is installed, let `ai-sync` materialize the RTK config declared in
`config/ai/registry.json` and automatically initialize supported global RTK
integrations:

```bash
ai-sync
```

By default this will run the equivalent of:

```bash
rtk init -g --auto-patch
rtk init -g --codex
rtk init -g --opencode
```

for enabled integrations that RTK supports natively. For OpenClaw, treat RTK as a
plugin/wrapper-style integration rather than a first-class `rtk init` target unless
your installed RTK version explicitly adds native support.

## Shell helpers

The zsh AI helpers expose these convenience commands:

- `rtk-check` — show RTK version/help
- `rtk-codex <args...>` — run Codex through RTK
- `rtk-claude <args...>` — run Claude through RTK
- `rtk-opencode <args...>` — run OpenCode through RTK
- `rtk-openclaw <args...>` — show a reminder for OpenClaw plugin-style setup

These helpers are intentionally light-touch: they add an ergonomic layer without hijacking
existing tool defaults.

## Registry-driven configuration

The RTK integration map lives under the top-level `rtk` key in
`config/ai/registry.json`.

That block controls:

- whether RTK integration is enabled
- where the local RTK config file is written
- which agent integrations are exposed
- which existing tool config paths are attached to each RTK integration
