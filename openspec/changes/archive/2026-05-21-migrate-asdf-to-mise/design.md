## Context

The development install path currently hardcodes `asdf` in four places: package installation, Dotbot shell steps, shell initialization, and installer post-checks. Runtime versions are set imperatively with `asdf plugin add`, `asdf install`, `asdf set -u`, and `asdf reshim`, while shell startup assumes `~/.asdf/shims` and a custom `script/load-asdf.sh` loader. This change is cross-cutting because it affects bootstrap commands, persistent user configuration, and user-facing documentation.

## Goals / Non-Goals

**Goals:**
- Replace `asdf` as the runtime manager used by development-mode installation.
- Keep installation behavior equivalent for Go, Python, Node.js, and Bun global runtimes.
- Ensure new shells activate `mise` without requiring users to source `asdf` scripts manually.
- Preserve a simple migration path for existing users who reinstall or refresh dotfiles.

**Non-Goals:**
- Migrating every project-level `.tool-versions` file outside this repository.
- Reworking unrelated package installation flows, AI tooling setup, or non-development modes.
- Cleaning up already-installed `asdf` runtimes under `~/.asdf` as part of the installer.

## Decisions

### Use `mise` native bootstrap and config

The installer will install `mise` through the existing package-manager path, then use `mise use --global` or an equivalent `mise settings/config` flow to declare global tool versions. A first-class `mise` config file is preferred over imperative one-off shell state because it is reproducible and reviewable in the repo.

Alternatives considered:
- Keep `asdf` and only replace shell integration. Rejected because plugin add/install/reshim complexity remains.
- Use `mise` only as an `asdf`-compat wrapper around `.tool-versions`. Rejected because it keeps the repo centered on legacy `asdf` concepts instead of declaring `mise` as the owner.

### Replace `load-asdf.sh` with a `mise` loader boundary

Current shell entry points (`config/zsh/zshrc.zsh`, `config/zsh/exec.sh`, `install.sh`) all rely on one shared loader script. The migration should preserve that single integration boundary, but the script should initialize `mise activate` and PATH expectations instead of exporting `ASDF_*` values.

Alternatives considered:
- Inline `eval "$(mise activate ...)"` in every file. Rejected because it duplicates logic and makes future changes error-prone.
- Rely only on the oh-my-zsh `mise` plugin. Rejected because non-interactive shells and installer scripts also need runtime activation.

### Remove `asdf`-specific post-install maintenance

`mise` does not require plugin registration or a global `reshim` step for the target runtimes. Installer logic should switch from `asdf current/list/set` health checks to `mise` equivalents that verify configured global tool versions and install missing runtimes idempotently.

Alternatives considered:
- Keep compatibility helpers that call both `asdf` and `mise`. Rejected because mixed ownership obscures the migration target and increases support burden.

## Risks / Trade-offs

- Existing users may still have `~/.asdf/shims` earlier in PATH → Update loader/PATH ordering so `mise` activation wins in new shells.
- `mise` command semantics differ from `asdf set -u` and plugin URLs → Encode exact runtime declarations in repo-managed config and validate them in installer steps.
- Linux/macOS package sources may not expose `mise` identically → Keep package-manager handling centralized in existing Dotbot shell blocks and document any OS-specific branch.
- Some scripts or user habits may still call `asdf` directly → Update docs and post-install guidance to point to `mise` commands and expected config locations.

## Migration Plan

1. Add repo-managed `mise` configuration and switch development package manifests/install hooks to install `mise`.
2. Replace `asdf` bootstrap scripts, PATH references, and zsh plugin wiring with `mise` activation.
3. Update installer post-checks to validate runtime presence through `mise`, removing plugin/reshim steps.
4. Rewrite user-facing docs, overwrite notices, and examples to describe `mise` instead of `asdf`.
5. Verify development install flow on at least one supported platform and confirm shells resolve runtimes from `mise`.

Rollback strategy:
- Revert the change set and restore `asdf` package/install hooks plus `load-asdf.sh`.
- Existing `~/.asdf` state is left untouched, so rollback does not require data migration.

## Open Questions

- Whether to store runtime defaults in `mise.toml` or `~/.config/mise/config.toml` via dotbot link.
- Whether Linux installation should use a package manager package, upstream install script, or `ghpkg` fallback.
- Whether any external automation in this repo depends on `.asdfrc` and needs a compatibility stub during migration.
