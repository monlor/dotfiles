# Agent Instructions

## Scope

- Follow the active repository root `AGENTS.md` first for repo-specific workflow, safety rules, and structure.
- Use this file only for cross-project behavior that should stay stable across machines and repositories.

## Configuration

- Treat repository-managed configuration as the default when a project provides it.
- Preserve user-specific overrides unless a task explicitly targets personal configuration.
- Avoid hard-coding machine-specific paths or assuming one dotfiles layout.

## Default Tooling

- Default to terse, high-signal communication: compact technical output, no filler, expand only when detail matters.
- Prefer fast local search (e.g. `rg`) for symbol lookup and impact analysis.

## Development

- Prefer popular, actively maintained dependencies; avoid obsolete or inactive libraries.
- When a well-maintained dependency solves the problem, use it instead of building custom implementations.

## Multi-Agent

- Keep agent roles task-focused and explicit.
- Recommended roles:
  - `explorer` — read-only evidence gathering
  - `reviewer` — correctness, security, and test review
  - `docs-researcher` — documentation and release-note verification

## Git Workflow

When a PR needs updates (review feedback, bug fixes, refinements), prefer amending or rebasing over creating new commits:

- **Amend** the last commit if the update is a direct correction: `git commit --amend --no-edit`
- **Interactive rebase** to fold changes into an earlier commit: `git rebase -i main`
- **Force push** after rewriting history: `git push --force`

Only create a new commit when the change is a genuinely separate concern. Never leave commits named "fix review comment" or "address feedback".

## External Actions

- Treat networked or third-party actions as read-only by default.
- Require explicit user approval before posting, publishing, pushing, merging, changing credentials, or modifying third-party resources.
- When approval is unclear, prepare a local draft, patch, or plan instead of taking the external action.
