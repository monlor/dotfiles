#!/bin/bash

# bat theme switcher - adaptive to macOS appearance mode

get_macos_appearance() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Get macOS appearance mode
        local mode=$(defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light")
        echo "$mode"
    else
        # Default to Dark for non-macOS
        echo "Dark"
    fi
}

set_bat_theme() {
    local appearance=$(get_macos_appearance)

    if [[ "$appearance" == "Dark" ]]; then
        # Dark mode themes (choose one that looks good)
        export BAT_THEME="Monokai Extended Bright"
    else
        # Light mode themes
        export BAT_THEME="GitHub"
    fi
}

# Set the theme
set_bat_theme

# If called with --print, just print the theme name
if [[ "$1" == "--print" ]]; then
    echo "$BAT_THEME"
fi