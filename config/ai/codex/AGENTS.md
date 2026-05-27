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
