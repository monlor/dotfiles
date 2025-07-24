# CLAUDE.md - Dotfiles Management Guidelines

Never execute the install.sh script. There is no need to test the script

## Commands

### Dotbot Commands
- Update dotbot modules: `git submodule update --init --recursive`
- Apply configuration: `./dotbot/bin/dotbot -c dotbot/install.conf.yaml`

## Code Style Guidelines

### Shell Scripts
- Start with `#!/bin/bash` and `set -e` for error handling
- Use descriptive variable names in lowercase
- Follow modular organization pattern (functions, aliases, path)
- Use while loops instead of mapfile for POSIX compatibility
- Add comments for non-obvious code sections

### File Organization
- Keep related configurations in dedicated directories
- Use descriptive suffixes: `.aliases.sh`, `.functions.sh`, `.path.sh`
- Platform-specific code should be in dedicated files
- User customizations go in `.user` files (never committed)

### Commit Style
- Follow conventional commits: `feat:`, `fix:`, `docs:`, etc.
- Include emoji in commit messages (🎸)
- Keep commits focused on a single change
- Use descriptive, concise commit messages in English