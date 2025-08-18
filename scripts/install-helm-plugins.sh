#!/bin/bash
set -e

# Install helm plugins, skipping already installed ones
# Usage: ./install-helm-plugins.sh plugin1:url1 plugin2:url2 ...
# Usage: ./install-helm-plugins.sh diff:https://github.com/databus23/helm-diff

# Global variable to cache installed plugins
INSTALLED_PLUGINS=""

# Function to get installed plugins list (cached)
get_installed_plugins() {
    if [ -z "$INSTALLED_PLUGINS" ]; then
        INSTALLED_PLUGINS=$(helm plugin list 2>/dev/null || echo "")
    fi
    echo "$INSTALLED_PLUGINS"
}

# Function to check if a plugin is installed
is_plugin_installed() {
    local plugin="$1"
    local installed_list
    installed_list=$(get_installed_plugins)
    echo "$installed_list" | grep -q "^$plugin\s" 2>/dev/null
}

# Function to install a single plugin
install_plugin() {
    local plugin_spec="$1"
    local plugin_name
    local plugin_url
    
    # Parse plugin specification (name:url or just name)
    if [[ "$plugin_spec" == *":"* ]]; then
        plugin_name="${plugin_spec%%:*}"
        plugin_url="${plugin_spec#*:}"
    else
        plugin_name="$plugin_spec"
        plugin_url="$plugin_spec"
    fi
    
    if is_plugin_installed "$plugin_name"; then
        echo "✓ Plugin '$plugin_name' is already installed, skipping..."
        return 0
    fi
    
    echo "→ Installing helm plugin: $plugin_name"
    if [[ "$plugin_url" == http* ]]; then
        echo "  URL: $plugin_url"
    fi
    
    if helm plugin install "$plugin_url"; then
        echo "✓ Successfully installed plugin: $plugin_name"
        # Update cache after successful installation
        INSTALLED_PLUGINS=""
        return 0
    else
        echo "✗ Failed to install plugin: $plugin_name" >&2
        return 1
    fi
}

# Function to check if helm is available
check_helm() {
    if ! command -v helm >/dev/null 2>&1; then
        echo "Error: helm not found. Please install helm first." >&2
        exit 1
    fi
    
    if ! helm version >/dev/null 2>&1; then
        echo "Error: helm is not working properly." >&2
        exit 1
    fi
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 plugin1:url1 plugin2:url2 ..."
        echo "Usage: $0 plugin_name (if plugin name matches repository URL)"
        echo ""
        echo "Examples:"
        echo "  $0 diff:https://github.com/databus23/helm-diff"
        echo "  $0 secrets:https://github.com/jkroepke/helm-secrets"
        echo "  $0 https://github.com/chartmuseum/helm-push"
        echo ""
        echo "Common plugins:"
        echo "  diff     - Compare revisions, check changes before upgrade"
        echo "  secrets  - Manage secrets in Helm charts"
        echo "  push     - Push charts to ChartMuseum"
        echo "  unittest - Unit test charts locally"
        exit 1
    fi
    
    echo "🔧 Helm Plugin Installation Script"
    echo "=================================="
    
    # Check prerequisites
    check_helm
    
    echo "📦 Installing plugins: $*"
    echo "🔍 Checking which plugins are already installed..."
    
    local installed_count=0
    local skipped_count=0
    local failed_count=0
    local failed_plugins=()
    
    for plugin_spec in "$@"; do
        local plugin_name
        if [[ "$plugin_spec" == *":"* ]]; then
            plugin_name="${plugin_spec%%:*}"
        else
            plugin_name="$plugin_spec"
        fi
        
        if is_plugin_installed "$plugin_name"; then
            echo "✓ Plugin '$plugin_name' is already installed, skipping..."
            ((skipped_count++))
        else
            if install_plugin "$plugin_spec"; then
                ((installed_count++))
            else
                ((failed_count++))
                failed_plugins+=("$plugin_name")
            fi
        fi
    done
    
    echo ""
    echo "📊 Installation Summary:"
    echo "   ✓ Installed: $installed_count plugins"
    echo "   → Skipped: $skipped_count plugins (already installed)"
    
    if [ $failed_count -gt 0 ]; then
        echo "   ✗ Failed: $failed_count plugins"
        echo "   Failed plugins: ${failed_plugins[*]}"
        echo ""
        echo "🔧 To see available plugins, visit: https://helm.sh/docs/community/related/"
        exit 1
    fi
    
    echo ""
    echo "🎉 All plugins processed successfully!"
    echo "📋 To list installed plugins, run: helm plugin list"
}

# Run main function with all arguments
main "$@"