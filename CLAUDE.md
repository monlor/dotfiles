# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a **dotfiles management system** using Dotbot for cross-platform configuration synchronization. The architecture follows a modular, layered approach:

### Core Components
- **Dotbot Engine**: Configuration management via `install.conf.yaml`
- **Multi-Mode Installation**: Minimal, DevOps, Development, Desktop installation profiles
- **Modular Configuration**: Platform-specific and tool-specific organization
- **Version Management**: Git submodules for external dependencies (oh-my-zsh, zgen)

### Directory Structure
```
config/              # All configuration files
├── zsh/            # Shell configurations (aliases, functions, paths)
├── git/            # Git configuration and templates
├── nvim/           # Neovim configuration
├── tmux/           # Terminal multiplexer config
├── scripts/        # Utility scripts linked to ~/.local/bin
├── mcp/            # MCP (Model Context Protocol) configurations
└── [tool]/         # Tool-specific configurations

modules/            # Git submodules
├── oh-my-zsh/      # ZSH framework
└── zgen/           # ZSH plugin manager

dotbot/             # Dotbot installation configurations
├── minimal/        # Minimal mode configs
├── devops/         # DevOps mode configs
├── development/    # Development mode configs
└── desktop/        # Desktop mode configs

scripts/            # OS-specific installation scripts
├── install-apt.sh  # APT package installer
├── install-yum.sh  # YUM package installer
├── install-apk.sh  # APK package installer
└── install-*.sh    # Other installation scripts

package/            # Package definitions by OS
├── brew/           # Homebrew packages (macOS)
├── apt/            # APT packages (Debian/Ubuntu)
├── yum/            # YUM packages (CentOS/RHEL)
└── apk/            # APK packages (Alpine)
```

### Configuration Philosophy
- **Modular Organization**: Related configs grouped by tool/domain
- **Platform Awareness**: OS-specific configurations and conditionals
- **User Customization**: `.user` files for personal overrides (never committed)
- **Forced Synchronization**: Core configs overwritten to maintain consistency
- **Package Installation**: Use `scripts/install-*.sh` scripts to install packages from `package/` directory files

## Common Commands

### Installation and Setup
```bash
# Full interactive installation (mode selection)
make install

# Direct mode installation
./install.sh --mode devops
./install.sh --mode development
./install.sh --mode desktop --yes

# Update dotbot submodules
git submodule update --init --recursive

# Apply configuration changes (after modifying install.conf.yaml)
./dotbot/bin/dotbot -c install.conf.yaml
```

### Configuration Management
```bash
# Update all git submodules forcefully
git submodule foreach --recursive '
  branch=$(git rev-parse --abbrev-ref HEAD);
  git fetch origin;
  git reset --hard origin/$branch;
  git clean -fdx;
'

# Homebrew package management (macOS)
make brew_install       # Install Homebrew

# Backup/restore application configs (macOS)
make backup
```

### Development Workflows
```bash
# ASDF version management (installed in development mode)
asdf list                    # List installed versions
asdf install golang 1.21.0  # Install specific version
asdf global python 3.12.3   # Set global version

# MCP setup verification
ls ~/.cursor/mcp.json        # Cursor MCP config
ls ~/.gemini/settings.json   # Gemini CLI MCP config

# kubectl krew plugin management
kubectl krew list            # List installed plugins
kubectl krew search          # Search available plugins
kubectl krew install <plugin>  # Install specific plugin

# Available plugins (auto-installed):
# - neat: Clean up kubectl output
# - pv-migrate: Persistent volume migration
# - ns: Namespace switching
# - ctx: Context switching  
# - status: Show resource status
# - view-utilization: Resource utilization
# - score: Security score analysis
# - view-secret: View secrets
# - node-shell: Node shell access
# - kc: Kubectl shortcuts
# - grep: Search resources
# Note: 'tree' and 'get-all' plugins removed on non-macOS systems
```

## Configuration Architecture

### ZSH Configuration System
The ZSH setup uses a **layered loading system**:
1. **Base Config** (`zshrc.zsh`): Core zsh settings, history, zgen plugin loading
2. **Modular Loading**: Automatic loading of organized config files:
   - `path/*.path.sh` → PATH modifications
   - `init/*.init.sh` → Initialization scripts  
   - `aliases/*.aliases.sh` → Command aliases
   - `functions/*.functions.sh` → Shell functions
3. **User Overrides**: `~/.zshrc.user` for personal customizations
4. **Secrets Management**: `~/.secrets` for environment variables (API keys, tokens)

### Plugin Management via zgen
- **oh-my-zsh plugins**: git, github, sudo, docker, etc.
- **Community plugins**: zsh-z, zsh-syntax-highlighting, zsh-autosuggestions
- **Custom plugins**: monlor/zsh-ai-assist for AI assistance

### Cross-Platform Compatibility
- **Conditional Installation**: macOS-specific configs (iterm2, mackup)
- **Package Managers**: brew (macOS), apt/yum/apk (Linux)
- **Architecture Detection**: ARM64 vs x86_64 Homebrew paths
- **OS Detection**: Platform-specific scripts and configurations

## Key Configuration Patterns

### Environment Variable Management
- **Secrets File** (`config/zsh/secrets`): API keys and sensitive config
- **Path Management** (`config/zsh/path/`): Platform-specific PATH modifications
- **Tool Integration**: ASDF, FZF, Starship, GPG, AWS configurations

### Tool Integration Architecture
- **ASDF**: Language version management (Python, Node, Go)
- **Starship**: Cross-shell prompt with custom config
- **FZF**: Fuzzy finder integration with custom key bindings
- **Tmux**: Terminal multiplexer with custom status line
- **Neovim**: Editor configuration with plugin management

### MCP (Model Context Protocol) Integration
- **Claude Code**: MCP configuration for enhanced AI assistance
- **Gemini CLI**: Google AI integration with MCP
- **Cursor**: IDE MCP configuration for development

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

## Security and Secrets Management

### Secret File Structure
- API keys organized by service (ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.)
- Model configuration variables (ANTHROPIC_MODEL)
- Service configurations (FRP, AGE encryption)
- Never commit actual secret values

### User Configuration Pattern
- `.user` files for personal overrides (`.zshrc.user`, `.gitconfig.user`)
- Secrets template copied during installation but never committed
- Platform-specific user customizations supported

## Important Notes

- **Never execute** `install.sh` directly when testing - use `make install` for safety
- **Backup warning**: Installation forcefully overwrites many configuration files (see CONFIG_OVERRIDES.md)
- **Submodule management**: Use provided commands for updating external dependencies
- **Multi-platform support**: Debian/Ubuntu, CentOS/RHEL/Fedora, Alpine Linux, macOS
  - **Fedora Support**: Enhanced with automatic dnf detection, proper repository configuration, and package name compatibility