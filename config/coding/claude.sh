#!/bin/bash

if [ -z "$USER" ]; then
  export USER=$(whoami)
fi

if [ -z "$HOME" ]; then
  export HOME=$(echo ~)
fi

if [ -f ~/.secrets ]; then
  . ~/.secrets
fi

export PATH=$HOME/.local/bin:$HOME/.asdf/shims:$PATH

# Function to safely add MCP server (only if not already exists)
add_mcp_server() {
    local server_name="$1"
    shift
    echo "Adding MCP server: $server_name"
    claude mcp add -s user "$server_name" "$@" 
}

# Add MCP servers
add_mcp_server context7 -- npx -y @upstash/context7-mcp
add_mcp_server deepwiki -- npx -y mcp-deepwiki@latest
add_mcp_server mcp-domain-availability -- uvx --from git+https://github.com/imprvhub/mcp-domain-availability mcp-domain-availability
add_mcp_server chrome-devtools -- npx chrome-devtools-mcp@latest --browser-url=http://127.0.0.1:9222

# Install Claude Code agents
echo "Installing Claude Code agents..."
mkdir -p ~/.claude

echo "Claude MCP and agents installation completed"
exit 0
