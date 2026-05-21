# Codex CLI Notes

This file is the project-managed content for `~/.codex/AGENTS.md`.

## Scope

- Follow the repository root `AGENTS.md` first for repo-specific workflow, safety rules, and structure.
- Use this file only for Codex-specific behavior that is not already covered there.

## Codex Defaults

- Treat `config/ai/codex/config.toml` as the project baseline for Codex settings.
- Keep project-managed Codex config in `config/ai/codex/`.
- Preserve user-specific overrides in `~/.codex/config.toml` unless a task explicitly targets them.

## Agents

- Multi-agent support is enabled in the project config.
- Project-local agent roles live under `config/ai/codex/agents/`.
- Available roles:
  - `explorer` for read-only evidence gathering
  - `reviewer` for correctness, security, and test review
  - `docs-researcher` for documentation and release-note verification

## Prompts

- Project prompt templates live under `config/ai/codex/prompts/`.
- OpenSpec prompts may refer to `openspec/AGENTS.md` when that directory exists in the checkout.

## External Actions

- Treat networked or third-party actions as read-only by default.
- Require explicit user approval before posting, publishing, pushing, merging, changing credentials, or modifying third-party resources.
- When approval is unclear, prepare a local draft or plan instead of taking the external action.
