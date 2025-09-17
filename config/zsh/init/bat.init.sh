# bat adaptive theme configuration

# Source the bat theme switcher (script is symlinked to ~/.local/bin)
BAT_THEME_SCRIPT="$HOME/.local/bin/bat-theme-switcher.sh"
if [[ -f "$BAT_THEME_SCRIPT" ]]; then
    source "$BAT_THEME_SCRIPT"
fi

# Create bat wrapper function for dynamic theme switching
bat() {
    # Set adaptive theme before running bat
    source "$BAT_THEME_SCRIPT" 2>/dev/null || true
    command bat "$@"
}

# Aliases for common bat usage
alias cat='bat --paging=never'
alias less='bat'