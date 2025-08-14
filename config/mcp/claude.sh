#!/bin/sh

if [ -z "$USER" ]; then
  export USER=$(whoami)
fi

if [ -z "$HOME" ]; then
  export HOME=$(echo ~)
fi

if [ -f ~/.secrets ]; then
  source ~/.secrets
fi

export PATH=$HOME/.local/bin:$HOME/.asdf/shims:$PATH

claude mcp add -s user context7 -- npx -y @upstash/context7-mcp
claude mcp add -s user puppeteer -- npx -y @modelcontextprotocol/server-puppeteer
claude mcp add -s user playwright -- npx -y @playwright/mcp@latest
claude mcp add -s user deepwiki -- npx -y mcp-deepwiki@latest
claude mcp add -s user task-master-ai -- npx -y --package=task-master-ai task-master-ai
claude mcp add -s user mcp-domain-availability -- uvx --from git+https://github.com/imprvhub/mcp-domain-availability mcp-domain-availability
if [ -n "$MAGIC_API_KEY" ]; then
  claude mcp add -s user magic -e API_KEY="$MAGIC_API_KEY" -- npx -y @21st-dev/magic@latest
fi
if [ -n "$DEV_PG_URI" ]; then
  claude mcp add -s user postgres-dev -e DATABASE_URI="$DEV_PG_URI" -- uvx --from git+https://github.com/crystaldba/postgres-mcp.git postgres-mcp --access-mode=unrestricted
fi
if [ -n "$DEV_REDIS_URI" ]; then
  claude mcp add -s user redis-dev -- uvx --from git+https://github.com/redis/mcp-redis.git redis-mcp-server --url $DEV_REDIS_URI
fi
if [ -n "$SUPABASE_ACCESS_TOKEN" ]; then
  claude mcp add -s user supabase -e SUPABASE_ACCESS_TOKEN="$SUPABASE_ACCESS_TOKEN" -- npx -y @supabase/mcp-server-supabase@latest
fi

exit 0