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
add_mcp_server codex -- npx -y codex-mcp-server

# Conditional MCP servers based on environment variables
if [ -n "$SUPABASE_ACCESS_TOKEN" ]; then
  add_mcp_server supabase -e SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" -- npx -y @supabase/mcp-server-supabase@latest
fi

# Install Claude Code agents
echo "Installing Claude Code agents..."
mkdir -p ~/.claude

if [ ! -d ~/.claude/agents ]; then
    echo "Cloning agents repository..."
    git clone https://github.com/wshobson/agents.git ~/.claude/agents || echo "Warning: Failed to clone agents repository"
else
    echo "Updating agents repository..."
    cd ~/.claude/agents
    git pull || echo "Warning: Failed to update agents repository"
fi

echo "Claude MCP and agents installation completed"
exit 0
