# Codex Agent Best Practices

## Scope

- Follow the active repository root `AGENTS.md` first for repo-specific workflow, safety rules, and structure.
- Use this file only for cross-project Codex behavior that should stay stable across machines and repositories.

## Configuration

- Treat repository-managed Codex configuration as the default when a project provides it.
- Preserve user-specific overrides unless a task explicitly targets personal configuration.
- Avoid hard-coding machine-specific paths or assuming one dotfiles layout.

## Default Tooling

- Prefer `rtk` for shell commands when it is available on the host.
- Default to terse, high-signal communication in the style of `caveman`: compact technical output, no filler, expand only when detail matters.
- Prefer CodeGraph for symbol lookup, impact analysis, callers, and callees when the current project has an initialized graph.
- If CodeGraph is unavailable or not initialized, fall back to fast local search such as `rg`.

## Codex Plugins

- Prefer the in-app Browser plugin for local web app inspection when it exposes browser control tools. Use it for `localhost`, `127.0.0.1`, `::1`, file previews, and post-frontend-change screenshots or layout checks when Chrome state is not required.
- Use the Chrome plugin when the user explicitly asks for Chrome, when the task depends on the user's real Chrome profile, cookies, login state, existing tabs, or Chrome extensions, or when in-app Browser control is unavailable and real browser verification is still needed.
- When using the Chrome plugin, control it through the plugin-provided browser client in `node_repl`; read the plugin documentation first, claim only tabs returned by the current open-tabs call, avoid inspecting cookies/local storage/passwords, and finalize browser tabs before ending the turn.
- Use Computer Use for desktop-app control, keyboard input, simple browser scrolling, or fallback interaction when browser plugins are unavailable. Do not treat Computer Use as a reliable DOM, console, network, or visual-inspection tool unless those capabilities are explicitly exposed.
- Use HTTP commands such as `curl` only as a fallback for response or endpoint validation. Clearly label them as HTTP validation, not browser verification.
- After significant frontend changes, start the local dev server if needed and verify with the strongest available browser surface: in-app Browser first for ordinary local UI checks, Chrome plugin for Chrome-specific or requested checks, Computer Use only for mechanical interaction.
- Never present a fallback check as if it were a stronger tool. If the requested plugin capability is unavailable in the current turn, say which capability is missing and what fallback was used.

## Development

- Prefer popular, actively maintained dependencies and avoid obsolete or inactive libraries.
- When a well-maintained dependency solves the problem, use it instead of building custom implementations, unless project constraints clearly require bespoke code.

## Agents

- Multi-agent support may be used when the project enables it.
- Keep agent roles task-focused and explicit.
- Recommended roles:
  - `explorer` for read-only evidence gathering
  - `reviewer` for correctness, security, and test review
  - `docs-researcher` for documentation and release-note verification

## Prompts

- Prefer project-managed prompt templates when a repository provides them.
- When OpenSpec or similar workflow docs exist in the checkout, follow those local instructions before applying generic prompting conventions.

## External Actions

- Treat networked or third-party actions as read-only by default.
- Require explicit user approval before posting, publishing, pushing, merging, changing credentials, or modifying third-party resources.
- When approval is unclear, prepare a local draft, patch, or plan instead of taking the external action.
