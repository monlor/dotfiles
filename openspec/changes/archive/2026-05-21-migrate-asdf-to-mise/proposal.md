## Why

The development profile currently depends on `asdf` across installation, shell initialization, and runtime bootstrap, which adds plugin-management overhead and spreads `asdf`-specific assumptions through the dotfiles. Migrating to `mise` now simplifies runtime management, aligns with tooling already vendored in `oh-my-zsh`, and removes a legacy dependency before more workflows build on it.

## What Changes

- Replace `asdf` installation and runtime provisioning in the development profile with `mise`.
- Update shell startup and PATH/bootstrap logic to initialize `mise` instead of sourcing `asdf` scripts.
- Move global runtime defaults for Go, Python, Node.js, and Bun to `mise`-managed configuration.
- Update documentation, override notices, and commands that currently instruct users to use `asdf`.
- Remove `asdf`-specific maintenance steps such as plugin registration and reshim operations.

## Capabilities

### New Capabilities
- `mise-runtime-management`: Manage developer runtimes through `mise`, including install, activation, and global defaults during dotfiles setup.

### Modified Capabilities
- None.

## Impact

- Affected code: `dotbot/development/install.65-dev.yaml`, `install.sh`, `config/zsh/*`, `script/load-asdf.sh` or its replacement, package manifests, and setup documentation.
- Affected dependencies: Homebrew/Linux package install path for runtime manager, shell plugin selection, and global runtime config files.
- Affected systems: development-mode bootstrap, interactive shell startup, global language runtime selection, and post-install guidance.
