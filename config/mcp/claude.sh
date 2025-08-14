#!/bin/sh

if [ -z "$USER" ]; then
  export USER=$(whoami)
fi

if [ -z "$HOME" ]; then
  export HOME=$(echo ~)
fi

export PATH=$HOME/.local/bin:$HOME/.asdf/shims:$PATH

claude mcp add -s user context7 -- npx -y @upstash/context7-mcp
claude mcp add -s user sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add -s user puppeteer -- npx -y @modelcontextprotocol/server-puppeteer
claude mcp add -s user time -- uvx mcp-server-time
claude mcp add -s user magic -e API_KEY="\$MAGIC_API_KEY" -- npx -y @21st-dev/magic@latest
claude mcp add -s user playwright -- npx -y @playwright/mcp@latest
claude mcp add -s user deepwiki -- npx -y mcp-deepwiki@latest
claude mcp add -s user task-master-ai -- npx -y --package=task-master-ai task-master-ai

exit 0