# bat aliases with adaptive theme support

# Check for bat command (could be 'bat' on macOS/homebrew or 'batcat' on Linux)
if type bat >/dev/null 2>&1 || type batcat >/dev/null 2>&1; then
  # Override cat command to use batx wrapper (with adaptive theme)
  alias cat='batx -p'

  # Alternative bat command for paged output
  alias less='batx'

  # Override bat command to use wrapper with adaptive theme
  alias bat='batx'

  # Show bat with line numbers (useful for debugging)
  alias batn='batx --style=numbers'

  # Show bat without decorations (plain text)
  alias batp='batx --style=plain'
fi
