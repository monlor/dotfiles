# Agent Instructions

## Scope

- Follow the project-local `AGENTS.md` or `CLAUDE.md` first for repo-specific workflow, safety rules, and structure.

## Development

- Prefer a well-maintained library over a custom implementation. Search npm / PyPI / pkg.go.dev / crates.io first; only build custom if nothing suitable exists or the dependency cost is clearly worse.

## Git Workflow

When a PR needs updates (review feedback, bug fixes, refinements), prefer amending or rebasing over creating new commits:

- **Amend** the last commit if the update is a direct correction and has not been pushed, or you are force-pushing your own branch: `git commit --amend --no-edit`
- **Interactive rebase** to fold changes into an earlier commit: `git rebase -i main`
- **Force push** only your own branch after rewriting history: `git push --force`. Do not force-push `main` / `master` or anyone else's branch unless the user explicitly asks.

Only create a new commit when the change is a genuinely separate concern. Never leave commits named "fix review comment" or "address feedback".

## Change Safety

- Before making any changes, assess blast radius and reversibility.
- If the risk is high — destructive, hard to reverse, shared or external state, unclear scope — stop and confirm.
- Treat networked or third-party actions as read-only until the user explicitly approves posting, publishing, pushing, merging, changing credentials, or modifying third-party resources.

## Output style

The reader has ADHD. Shape every response so it can be acted on:

1. Lead with the answer or next action: command, path, or snippet first.
2. Number multi-step work; one bounded action per step.
3. End with one next action doable in under two minutes.
4. Finish the current issue before raising a new one.
5. Restate progress each turn ("step 3 of 5 done").
6. Give time estimates in concrete units, never "a bit".
7. After a change, show what now works.
8. Errors: state location, cause, and fix. No drama.
9. Cap lists to 5 items.
10. No preamble, no recaps, no closers.

Exceptions: explain fully when asked to explain. Confirm before destructive actions. After three failed fixes, stop and name the doubtful assumption. If the request is ambiguous, ask one short question.

<!-- codebase-memory-mcp:start -->
# Codebase Knowledge Graph (codebase-memory-mcp)

This project uses codebase-memory-mcp to maintain a knowledge graph of the codebase.
ALWAYS prefer graph tools over grep/glob/file-search for code discovery.

### Priority Order
1. `search_graph` — find functions, classes, routes, variables by pattern
2. `trace_path` — trace who calls a function or what it calls
3. `get_code_snippet` — read specific function/class source code
4. `check_index_coverage` — validate candidate paths and missed ranges before claims
5. `query_graph` — run Cypher queries for complex patterns
6. `get_architecture` — high-level project summary

### Evidence tiers
- **Scout (Tier 1):** quick positive lookup with few calls and targeted source checks. Mark it provisional; do not make negative or exhaustive claims.
- **Verify (Tier 2, default):** task-directed graph evidence, relevant trace directions, exact snippets for material claims, and relevant pagination.
- **Auditor (Tier 3):** bounded-scope full verification with current generation, complete relevant pagination, both call directions and broader relationships when material, and every limitation disclosed.
- After candidate paths are known in any tier, call `check_index_coverage` once with every evidence path. Add relevant scopes for negative or exhaustive claims. A clean result means no recorded gap, not proof of completeness. For partial, skipped, excluded, stale, pending, or unknown coverage, read/grep the reported ranges or scope before relying on graph results.

### When to fall back to grep/glob
- Searching for string literals, error messages, config values
- Searching non-code files (Dockerfiles, shell scripts, configs)
- When graph tools return insufficient results

### Examples
- Find a handler: `search_graph(name_pattern=".*OrderHandler.*")`
- Who calls it: `trace_path(function_name="OrderHandler", direction="inbound")`
- Read source: `get_code_snippet(qualified_name="pkg/orders.OrderHandler")`

### Session resets and subagents
- At session start or after compaction, confirm the nearest graph project and generation with `list_projects` or `index_status`, then choose Scout, Verify, or Auditor.
- Before spawning a subagent, query the graph and coverage in the parent. Pass the tier, project, generation/freshness, bounded scope, queries and pagination state, qualified symbols, paths, call-chain findings, coverage evidence with ranges/reasons, source fallback already performed, and unresolved questions in the delegated task context.
- Do not assume subagents inherit MCP or graph-tool access or the parent conversation. If a child lacks those tools, it must not call or claim them. It should use the supplied evidence and read/grep exact source, especially every reported missed-coverage range.
<!-- codebase-memory-mcp:end -->
