# Codex Agent Instructions

See `~/.agents/AGENTS.md` (or `config/ai/AGENTS.md` in dotfiles) for the canonical cross-project agent instructions.

## Codex Plugins

- Prefer the in-app Browser plugin for local web app inspection. Use it for `localhost`, `127.0.0.1`, file previews, and post-frontend-change layout checks.
- Use the Chrome plugin when the task depends on the user's real Chrome profile, cookies, login state, or extensions.
- Use Computer Use for desktop-app control or fallback interaction when browser plugins are unavailable.
- Use HTTP commands (`curl`) only as a fallback for endpoint validation.
- Never present a fallback check as if it were a stronger tool.
