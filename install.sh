#!/bin/bash

set -e

DOTBOT_DIR="modules/dotbot"
DOTBOT_BIN="bin/dotbot"
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Default install mode (will be set interactively if not provided)
INSTALL_MODE=${INSTALL_MODE:-""}
# Confirmation prompt (default: require confirmation)
SKIP_CONFIRM=${SKIP_CONFIRM:-false}

# Supported install modes
VALID_MODES=("minimal" "development" "desktop")

# Show help
show_help() {
    cat <<-EOF
Usage: $0 [options] [dotbot options]

Install modes:
  minimal      - Minimal install, basic configs
  development  - Development environment, includes ASDF and dev tools
  desktop      - Desktop environment, includes GUI apps and desktop configs

Options:
  -m, --mode MODE    Specify install mode (${VALID_MODES[*]})
  -y, --yes          Skip confirmation prompt
  -h, --help         Show this help message

Environment variables:
  INSTALL_MODE       Set install mode
  SKIP_CONFIRM       Set to true to skip confirmation

Examples:
  $0 --mode development
  $0 --mode desktop --yes
  INSTALL_MODE=desktop SKIP_CONFIRM=true $0
EOF
}

# Interactive mode selection
select_mode() {
    echo "Please select an installation mode:"
    echo "1) minimal      - Basic configuration for servers or minimal environments"
    echo "2) development  - Development environment with ASDF and dev tools"
    echo "3) desktop      - Full desktop environment with GUI apps"
    echo ""
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            INSTALL_MODE="minimal"
            ;;
        2)
            INSTALL_MODE="development"
            ;;
        3)
            INSTALL_MODE="desktop"
            ;;
        *)
            echo "Invalid choice. Please run the script again."
            exit 1
            ;;
    esac
}

# Parse arguments
DOTBOT_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            INSTALL_MODE="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            DOTBOT_ARGS+=("$1")
            shift
            ;;
    esac
done

# If no mode specified, prompt user to select
if [[ -z "$INSTALL_MODE" ]]; then
    select_mode
fi

# Validate install mode
if [[ ! " ${VALID_MODES[*]} " =~ " ${INSTALL_MODE} " ]]; then
    echo "Error: Invalid install mode '${INSTALL_MODE}'"
    echo "Supported modes: ${VALID_MODES[*]}"
    exit 1
fi

cd "${BASEDIR}"
git submodule update --init --recursive --remote --merge

echo "Detecting operating system..."
# OS detection
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            "ubuntu"|"debian")
                echo "debian"
                ;;
            "centos"|"rhel"|"fedora")
                echo "centos"
                ;;
            "alpine")
                echo "alpine"
                ;;
            *)
                echo "Unsupported OS: $ID"
                exit 1
                ;;
        esac
    else
        echo "Unsupported OS: unknown"
        exit 1
    fi
}

OS=$(detect_os)
echo "Detected OS: ${OS}"
echo "Install mode: ${INSTALL_MODE}"

# Mode-specific required configs
declare -A MODE_CONFIGS=(
    ["minimal"]="dotbot/minimal/install.base.yaml"
    ["development"]="dotbot/development/install.asdf.yaml"
    ["desktop"]=""
)

# Mode dependency chain
declare -A MODE_DEPENDENCIES=(
    ["minimal"]=""
    ["development"]="minimal"
    ["desktop"]="minimal development"
)

# Plugin directory mapping
declare -A PLUGIN_MAP=(
    ["development"]="--plugin-dir ${BASEDIR}/modules/dotbot-asdf"
    ["desktop"]="--plugin-dir ${BASEDIR}/modules/dotbot-asdf --plugin-dir ${BASEDIR}/modules/dotbot-brewfile"
)

# Build config file list
build_configs() {
    local mode=$1
    local os=$2
    local configs=()
    local dependencies="${MODE_DEPENDENCIES[$mode]}"
    local all_modes=($dependencies $mode)
    for m in "${all_modes[@]}"; do
        local mode_configs="${MODE_CONFIGS[$m]}"
        if [[ -n "$mode_configs" ]]; then
            for config in $mode_configs; do
                configs+=("$config")
            done
        fi
        local system_config="dotbot/${m}/install.${os}.yaml"
        if [[ -f "$system_config" ]]; then
            configs+=("$system_config")
        fi
    done
    echo "${configs[@]}"
}

# Build plugin directory list
build_plugins() {
    local mode=$1
    local plugins=()
    local plugin_config="${PLUGIN_MAP[$mode]}"
    if [[ -n "$plugin_config" ]]; then
        plugins+=($plugin_config)
    fi
    echo "${plugins[@]}"
}

CONFIGS=($(build_configs "$INSTALL_MODE" "$OS"))
PLUGIN_DIRS=($(build_plugins "$INSTALL_MODE"))

echo "Checking config files..."
for config in "${CONFIGS[@]}"; do
    if [[ -f "$config" ]]; then
        echo "✓ Found config: $config"
    else
        echo "⚠ Config not found: $config"
    fi
done

echo ""
echo "Dotbot will install with the following configs:"
echo "* Install mode: ${INSTALL_MODE}"
echo "* OS: ${OS}"
echo "* Config files:"
for config in "${CONFIGS[@]}"; do
    if [[ -f "$config" ]]; then
        echo "  - $config"
    fi
done

if [[ ${#PLUGIN_DIRS[@]} -gt 0 ]]; then
    echo "* Plugin directories:"
    for plugin_dir in "${PLUGIN_DIRS[@]}"; do
        echo "  - $plugin_dir"
    done
fi
echo ""

if [[ "${SKIP_CONFIRM}" == "false" ]]; then
    read -p "Press Enter to continue, or Ctrl+C to cancel... " -r
fi

# Merge configuration files with empty lines between them
rm -rf install.conf.yaml
for config in "${CONFIGS[@]}"; do
    if [[ -f "$config" ]]; then
        cat "$config" >> install.conf.yaml
        echo "" >> install.conf.yaml
    fi
done

# Build dotbot command
DOTBOT_CMD=("${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}")
DOTBOT_CMD+=("${PLUGIN_DIRS[@]}")
DOTBOT_CMD+=("-d" "${BASEDIR}")
DOTBOT_CMD+=("-c" "install.conf.yaml")
DOTBOT_CMD+=("-x")
DOTBOT_CMD+=("${DOTBOT_ARGS[@]}")

echo "Running install command: ${DOTBOT_CMD[*]}"
echo ""

# Run install
"${DOTBOT_CMD[@]}"

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "* Run 'chsh -s \$(which zsh)' to set zsh as your default shell."
echo "* Run 'source ~/.zshrc' to reload your shell config."
echo "* Change your terminal font to a Nerd Font."
echo "* Run 'zsh' to start a new shell."

if [[ "${INSTALL_MODE}" == "development" || "${INSTALL_MODE}" == "desktop" ]]; then
    echo "* Run 'asdf reshim python' to ensure Python binaries are in your PATH."
fi

if [[ "${OS}" == "mac" ]]; then
    echo "* Run 'make brew_install' to restore all Homebrew packages."
    echo "* Run 'make backup' to backup all Mackup files to iCloud."
fi

echo ""
echo "If zgen initialization fails:"
echo "* zgen reset"
echo "* rm -rf ~/.zgen/zsh-users"
