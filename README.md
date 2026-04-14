# Dotfiles

**Check all the files before you install. It may break your configuration of your computer.**

## Features

* 📦 Dotbot: Effortless Configuration Management Across Devices
* 🗂️ All terminal configurations are managed in one Git repository.
* 🧰 Favorite tools and applications are tracked and installed with a single command.
* 🔄 Synchronized configurations ensure a consistent experience on any machine.
* 🚀 One-click setup for quickly initializing a new computer.

## Installation

> **⚠️ Before installation, please read [CONFIG_OVERRIDES.md](./CONFIG_OVERRIDES.md) to understand which configuration files will be forcefully overwritten!**

### Quick Start

```bash
# Clone the repository
git clone https://github.com/monlor/dotfiles ~/.dotfiles --recursive
cd ~/.dotfiles

# Install dotfiles (interactive mode selection)
make install
```

### Installation Modes

The installer supports three modes:

1. **Minimal** - Basic configuration for servers or minimal environments
2. **Development** - Development environment with ASDF and development tools
3. **Desktop** - Full desktop environment with GUI applications

### Mac Setup

```bash
# Install git if not installed
xcode-select --install

# Clone dotfiles
git clone https://github.com/monlor/dotfiles ~/.dotfiles --recursive
cd ~/.dotfiles

# Install Homebrew if not installed
make brew_install

# Load brew environment
source ~/.zprofile

# Install dotfiles (interactive mode selection)
make install

# Backup and restore application config from iCloud
make backup

```

### Linux Setup

```bash
# Install required packages
sudo apt-get install -y sudo git make curl

# Clone dotfiles
git clone https://github.com/monlor/dotfiles ~/.dotfiles --recursive 
cd ~/.dotfiles

# Install dotfiles (interactive mode selection)
make install
```

### Advanced Usage

You can also specify the installation mode directly:

```bash
# Install specific mode
./install.sh --mode development
./install.sh --mode desktop --yes  # Skip confirmation

# Using environment variables
INSTALL_MODE=desktop SKIP_CONFIRM=true ./install.sh
```

### Configure Git User

```bash
git config user.name "monlor"
git config user.email "me@monlor.com"
```

### Configure GitHub CLI

`gh` is installed from the Homebrew package set and zsh completion is enabled automatically.

After `make install`, finish authentication with:

```bash
gh auth login
gh auth status
```

This repo reserves `gh` for GitHub CLI.
The old git history shortcut is available as:

```bash
ghist
```

### Custom Configuration

* `~/.zshrc.user` (frps and openai config)
* `~/.gitconfig.user` (Set up your git user)

### AI Workspace Paths

Shared AI helper repos and generated plugin worktrees default to `~/.code`.
The current defaults are:

* `~/.code/plugins/compound-engineering-plugin`
* `~/.code/gstack`

### RTK Integration

This dotfiles repo includes an optional RTK integration layer.

What it does:

* installs `rtk` via Homebrew on macOS and `ghpkg rtk-ai/rtk` on Linux
* adds shell helpers for RTK-assisted Codex / Claude / OpenCode workflows
* generates RTK config from the shared AI registry
* runs supported `rtk init -g` setup automatically from `ai-sync`
* keeps the shared AI control plane as the source of truth

What it does not do:

* it does not force all tool calls through RTK
* it does not assume OpenClaw has a native first-class `rtk init` target

See `config/ai/rtk/README.md` for notes and the helper commands.

## Supported Operating Systems

- **macOS** - All installation modes supported
- **Debian/Ubuntu** - All installation modes supported  
- **CentOS/RHEL/Fedora** - All installation modes supported
- **Alpine Linux** - All installation modes supported

## Force Update Submodules

```bash
cd ~/.dotfiles
git submodule foreach --recursive '
  branch=$(git rev-parse --abbrev-ref HEAD);
  git fetch origin;
  git reset --hard origin/$branch;
  git clean -fdx;
'
```

## Inspired By

- https://github.com/denolfe/dotfiles
- https://github.com/craftzdog/dotfiles-public
- https://github.com/fisenkodv/dotfiles

## License

MIT
