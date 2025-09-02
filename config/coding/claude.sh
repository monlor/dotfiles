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
    
    if ! claude mcp list -s user | grep -q "^$server_name\s"; then
        echo "Adding MCP server: $server_name"
        claude mcp add -s user "$server_name" "$@" || echo "Warning: Failed to add $server_name"
    else
        echo "MCP server $server_name already exists, skipping"
    fi
}

# Add MCP servers
add_mcp_server context7 -- npx -y @upstash/context7-mcp
add_mcp_server playwright -- npx -y @playwright/mcp@latest
add_mcp_server deepwiki -- npx -y mcp-deepwiki@latest
add_mcp_server task-master-ai -- npx -y --package=task-master-ai task-master-ai
add_mcp_server mcp-domain-availability -- uvx --from git+https://github.com/imprvhub/mcp-domain-availability mcp-domain-availability

# Conditional MCP servers based on environment variables
if [ -n "$MAGIC_API_KEY" ]; then
  add_mcp_server magic -e API_KEY="$MAGIC_API_KEY" -- npx -y @21st-dev/magic@latest
fi
if [ -n "$DEV_PG_URI" ]; then
  add_mcp_server postgres-dev -e DATABASE_URI="$DEV_PG_URI" -- uvx --from git+https://github.com/crystaldba/postgres-mcp.git postgres-mcp --access-mode=unrestricted
fi
if [ -n "$DEV_REDIS_URI" ]; then
  add_mcp_server redis-dev -- uvx --from git+https://github.com/redis/mcp-redis.git redis-mcp-server --url $DEV_REDIS_URI
fi
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