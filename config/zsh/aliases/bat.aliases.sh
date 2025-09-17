# bat aliases with adaptive theme support

if type bat >/dev/null 2>&1; then
  # Override cat command to use batcat wrapper (with adaptive theme)
  alias cat='batcat --paging=never'

  # Alternative bat command for paged output
  alias less='batcat'

  # Override bat command to use wrapper with adaptive theme
  alias bat='batcat'

  # Show bat with line numbers (useful for debugging)
  alias batn='batcat --style=numbers'

  # Show bat without decorations (plain text)
  alias batp='batcat --style=plain'
fi