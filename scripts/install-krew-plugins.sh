#!/bin/bash
# Removed 'set -e' to allow proper error handling and continue installation of other plugins

# Install krew plugins, skipping already installed ones
# Usage: ./install-krew-plugins.sh plugin1 plugin2 plugin3 ...

# Load krew PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Global variable to cache installed plugins
INSTALLED_PLUGINS=""

# Function to get installed plugins list (cached)
get_installed_plugins() {
    if [ -z "$INSTALLED_PLUGINS" ]; then
        INSTALLED_PLUGINS=$(kubectl krew list 2>/dev/null || echo "")
    fi
    echo "$INSTALLED_PLUGINS"
}

# Function to check if a plugin is installed
is_plugin_installed() {
    local plugin="$1"
    local installed_list
    installed_list=$(get_installed_plugins)
    echo "$installed_list" | grep -q "^$plugin$" 2>/dev/null
}

# Function to install a single plugin
install_plugin() {
    local plugin="$1"
    
    if is_plugin_installed "$plugin"; then
        echo "✓ Plugin '$plugin' is already installed, skipping..."
        return 0
    fi
    
    echo "→ Installing krew plugin: $plugin"
    if kubectl krew install "$plugin"; then
        echo "✓ Successfully installed plugin: $plugin"
        # Update cache after successful installation
        INSTALLED_PLUGINS=""
        return 0
    else
        echo "✗ Failed to install plugin: $plugin" >&2
        return 1
    fi
}

# Function to check if krew is available
check_krew() {
    if ! command -v kubectl >/dev/null 2>&1; then
        echo "Error: kubectl not found. Please install kubectl first." >&2
        exit 1
    fi

    if ! kubectl krew version >/dev/null 2>&1; then
        echo "Error: krew not found. Please install krew first." >&2
        exit 1
    fi
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 plugin1 plugin2 plugin3 ..."
        echo "Example: $0 neat pv-migrate ns ctx status"
        exit 1
    fi
    
    echo "🔧 Krew Plugin Installation Script"
    echo "================================="
    
    # Check prerequisites - exit if kubectl/krew not available
    check_krew
    
    echo "📦 Installing plugins: $*"
    echo "🔍 Checking which plugins are already installed..."
    
    local installed_count=0
    local skipped_count=0
    local failed_count=0
    local failed_plugins=()
    
    # Continue processing all plugins even if some fail
    for plugin in "$@"; do
        if is_plugin_installed "$plugin"; then
            echo "✓ Plugin '$plugin' is already installed, skipping..."
            ((skipped_count++))
        else
            # Don't let plugin installation failure exit the entire script
            if install_plugin "$plugin"; then
                ((installed_count++))
            else
                ((failed_count++))
                failed_plugins+=("$plugin")
                echo "⚠️  Continuing with remaining plugins..."
            fi
        fi
    done
    
    echo ""
    echo "📊 Installation Summary:"
    echo "   ✓ Installed: $installed_count plugins"
    echo "   → Skipped: $skipped_count plugins (already installed)"

    if [ $failed_count -gt 0 ]; then
        echo "   ✗ Failed: $failed_count plugins (skipped)"
        echo "   Failed plugins: ${failed_plugins[*]}"
        echo ""
        echo "🔧 To see available plugins, run: kubectl krew search"
        echo "⚠️  Some plugins failed to install but continuing..."
    else
        echo ""
        echo "🎉 All plugins processed successfully!"
    fi

    echo "📋 To list installed plugins, run: kubectl krew list"
}

# Run main function with all arguments
main "$@"