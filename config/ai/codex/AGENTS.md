# Codex Agent Instructions

See the canonical cross-project agent instructions for global behavior and rules.

## Codex Plugins

- Prefer the in-app Browser plugin for local web app inspection. Use it for `localhost`, `127.0.0.1`, file previews, and post-frontend-change layout checks.
- Use the Chrome plugin when the task depends on the user's real Chrome profile, cookies, login state, or extensions.
- Use Computer Use for desktop-app control or fallback interaction when browser plugins are unavailable.
- Use HTTP commands (`curl`) only as a fallback for endpoint validation.
- Never present a fallback check as if it were a stronger tool.

<!-- codebase-memory-mcp:start -->
# Codebase Knowledge Graph (codebase-memory-mcp)

This project uses codebase-memory-mcp to maintain a knowledge graph of the codebase.
ALWAYS prefer MCP graph tools over grep/glob/file-search for code discovery.

## Priority Order
1. `search_graph` — find functions, classes, routes, variables by pattern
2. `trace_path` — trace who calls a function or what it calls
3. `get_code_snippet` — read specific function/class source code
4. `query_graph` — run Cypher queries for complex patterns
5. `get_architecture` — high-level project summary

## When to fall back to grep/glob
- Searching for string literals, error messages, config values
- Searching non-code files (Dockerfiles, shell scripts, configs)
- When MCP tools return insufficient results

## Examples
- Find a handler: `search_graph(name_pattern=".*OrderHandler.*")`
- Who calls it: `trace_path(function_name="OrderHandler", direction="inbound")`
- Read source: `get_code_snippet(qualified_name="pkg/orders.OrderHandler")`
<!-- codebase-memory-mcp:end -->
