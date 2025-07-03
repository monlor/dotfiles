# Installation Guide

This dotfiles repository supports three installation modes, suitable for different operating systems and usage scenarios.

## Installation Modes

### 1. Minimal
- **Purpose**: Basic configuration, suitable for servers or minimal environments
- **Includes**: Basic shell config, git config, essential tools
- **Always includes**: `install.base.yaml`

### 2. Development
- **Purpose**: Development environment configuration, suitable for developers
- **Includes**: Minimal + ASDF version manager, development tools, IDE config
- **Always includes**: `install.asdf.yaml`

### 3. Desktop
- **Purpose**: Full desktop environment configuration
- **Includes**: Development + GUI apps, desktop tools, complete config
- **Includes**: All config files and plugins

## Usage

### Command Line Options
```bash
# Default mode (minimal)
./install.sh

# Specify install mode
./install.sh --mode development
./install.sh --mode desktop

# Skip confirmation
./install.sh --mode desktop --yes

# Show help
./install.sh --help
```

### Environment Variables
```bash
# Set install mode
INSTALL_MODE=development ./install.sh
INSTALL_MODE=desktop ./install.sh

# Skip confirmation
SKIP_CONFIRM=true ./install.sh --mode development
```

## Supported Operating Systems

### macOS
- All three modes supported
- Automatically detects and uses macOS-specific configs
- Includes iTerm2, Mackup, and other macOS-specific settings

### Debian/Ubuntu
- All three modes supported
- Uses apt-based configs
- Includes development and desktop tools

### CentOS/RHEL/Fedora
- All three modes supported
- Uses yum-based configs
- Includes development and desktop tools

### Alpine Linux
- All three modes supported
- Uses apk-based configs
- Suitable for container environments

## Config File Structure

```
dotbot/
├── minimal/
│   ├── install.base.yaml      # Basic config (included in all modes)
│   ├── install.mac.yaml       # macOS-specific config
│   ├── install.debian.yaml    # Debian/Ubuntu-specific config
│   ├── install.centos.yaml    # CentOS/RHEL/Fedora-specific config
│   └── install.alpine.yaml    # Alpine-specific config
├── development/
│   ├── install.asdf.yaml      # ASDF config (included in development/desktop)
│   ├── install.mac.yaml       # macOS dev config
│   ├── install.debian.yaml    # Debian/Ubuntu dev config
│   ├── install.centos.yaml    # CentOS/RHEL/Fedora dev config
│   └── install.alpine.yaml    # Alpine dev config
└── desktop/
    ├── install.mac.yaml       # macOS desktop config
    ├── install.debian.yaml    # Debian/Ubuntu desktop config
    ├── install.centos.yaml    # CentOS/RHEL/Fedora desktop config
    └── install.alpine.yaml    # Alpine desktop config
```

## Installation Flow

1. **Detect OS**: Automatically detects macOS, Debian/Ubuntu, CentOS/RHEL/Fedora, Alpine, or exits if unsupported
2. **Select Mode**: Loads configs according to the selected mode and its dependencies
3. **Check Configs**: Verifies required config files exist, skips missing ones
4. **Merge Configs**: Merges all config files into a single config
5. **Run Install**: Uses dotbot to perform the installation
6. **Post Steps**: Shows next steps after installation

## Mode Dependency

- `minimal`: no dependencies
- `development`: includes minimal
- `desktop`: includes minimal and development

## Examples

### Install development environment on macOS
```bash
./install.sh --mode development
```

### Install desktop environment on Ubuntu
```bash
./install.sh --mode desktop
```

### Install minimal config on CentOS
```bash
./install.sh --mode minimal
```

### Install development environment in Alpine container
```bash
./install.sh --mode development
```

## Notes

- The script will automatically check for the existence of config files and skip missing ones
- Plugin directories are added automatically according to the install mode
- Detailed config info is shown before installation for confirmation
- Use `--yes` or `SKIP_CONFIRM=true` to skip confirmation in CI or automation 