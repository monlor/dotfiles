---
name: codebase-memory
description: Use the local Codebase Memory CLI for structural code queries. Triggers on: explore the codebase, architecture, functions, call chains, dependencies, impact analysis, dead code, graph queries, or codebase-memory.
---

# Codebase Memory — CLI-only

Use `$HOME/.local/bin/codebase-memory-mcp` (`$CBM`). Never invoke Codebase Memory through MCP.

```bash
CBM="${CODEBASE_MEMORY_MCP_BIN:-$HOME/.local/bin/codebase-memory-mcp}"
```

1. `"$CBM" cli list_projects`
2. If this repo is missing: `"$CBM" cli index_repository '{"repo_path":"/absolute/path"}'`
3. Query with one JSON object:

```bash
"$CBM" cli search_graph '{"project":"NAME","label":"Function","name_pattern":".*Handler.*"}'
"$CBM" cli trace_path '{"project":"NAME","function_name":"Search","direction":"both","depth":3}'
"$CBM" cli get_code_snippet '{"project":"NAME","qualified_name":"pkg.path.Func"}'
"$CBM" cli check_index_coverage '{"project":"NAME","paths":["file.go"]}'
"$CBM" cli index_status '{"project":"NAME"}'
"$CBM" cli detect_changes '{"project":"NAME"}'
```

Run `"$CBM" cli <tool> --help` when a schema is unclear.

Discover with the graph, then Read the cited source before concluding. Treat a narrow hit as provisional. For absence, impact, or dead-code claims, paginate and confirm with source search.
