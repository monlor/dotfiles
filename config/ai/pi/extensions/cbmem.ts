import { spawn } from "node:child_process";
import { Type } from "typebox";

const BIN = "/Users/monlor/.local/bin/codebase-memory-mcp";
const extra = { additionalProperties: true };

function snakeKey(key) {
  return key.replace(/([a-z0-9])([A-Z])/g, "$1_$2").replace(/-/g, "_").toLowerCase();
}

function snakeArgs(args) {
  if (!args || typeof args !== "object" || Array.isArray(args)) return args ?? {};
  const out = {};
  for (const [key, value] of Object.entries(args)) {
    out[snakeKey(key)] = value;
  }
  return out;
}

function formatResult(result) {
  if (typeof result === "string") return result;
  try {
    return JSON.stringify(result, null, 2);
  } catch {
    return String(result);
  }
}

async function call(tool, args, signal) {
  return new Promise((resolve) => {
    const child = spawn(BIN, ["cli", tool, JSON.stringify(args ?? {})], {
      stdio: ["ignore", "pipe", "pipe"],
      env: { ...process.env, CBM_LOG_LEVEL: "error" },
    });
    let out = "";
    let err = "";
    const onAbort = () => {
      if (!child.killed) child.kill();
    };
    signal?.addEventListener("abort", onAbort, { once: true });
    child.stdout.on("data", (d) => {
      out += d.toString();
    });
    child.stderr.on("data", (d) => {
      err += d.toString();
    });
    child.on("error", (e) => {
      signal?.removeEventListener("abort", onAbort);
      resolve({ error: String(e && e.message ? e.message : e) });
    });
    child.on("close", (code) => {
      signal?.removeEventListener("abort", onAbort);
      const lines = out.split("\n").map((l) => l.trim()).filter(Boolean);
      for (let i = lines.length - 1; i >= 0; i--) {
        try {
          return resolve(JSON.parse(lines[i]));
        } catch {
          /* keep scanning */
        }
      }
      resolve({
        error: err.trim() || out.trim() || `codebase-memory-mcp ${tool} exited ${code}`,
      });
    });
  });
}

function graphTool({ name, label, snippet, description, guidelines, properties }) {
  return {
    name,
    label,
    description,
    promptSnippet: snippet,
    promptGuidelines: guidelines,
    parameters: Type.Object(properties, extra),
    prepareArguments: snakeArgs,
    async execute(_id, params, signal) {
      const result = await call(name, params, signal);
      return {
        content: [{ type: "text", text: formatResult(result) }],
        details: result,
      };
    },
  };
}

const Str = () => Type.Optional(Type.String());
const Num = () => Type.Optional(Type.Number());
const Bool = () => Type.Optional(Type.Boolean());
const Arr = () => Type.Optional(Type.Array(Type.String()));

export default function (pi) {
  pi.registerTool(
    graphTool({
      name: "list_projects",
      label: "List Projects",
      snippet: "List indexed codebase-memory projects",
      description: "List indexed codebase-memory projects and their names.",
      guidelines: [
        "Call list_projects before search_graph, trace_path, or get_code_snippet so the project name is known.",
      ],
      properties: {
        offset: Num(),
        limit: Num(),
        include_details: Bool(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "search_graph",
      label: "Search Graph",
      snippet: "Find functions, classes, routes, and other symbols by pattern",
      description:
        "Search the code knowledge graph for symbols. Prefer this over grep for structural lookup.",
      guidelines: [
        "Use search_graph for structural symbol lookup. Use grep only for string literals, configs, and non-code files.",
      ],
      properties: {
        project: Type.String(),
        query: Str(),
        label: Str(),
        name_pattern: Str(),
        qn_pattern: Str(),
        file_pattern: Str(),
        relationship: Str(),
        min_degree: Num(),
        max_degree: Num(),
        exclude_entry_points: Bool(),
        include_connected: Bool(),
        semantic_query: Arr(),
        limit: Num(),
        offset: Num(),
        format: Str(),
        fields: Arr(),
        detail: Str(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "trace_path",
      label: "Trace Path",
      snippet: "Trace callers and callees of a function",
      description: "Trace inbound, outbound, or both call paths for a function.",
      properties: {
        project: Type.String(),
        function_name: Type.String(),
        direction: Str(),
        depth: Num(),
        limit: Num(),
        cursor: Str(),
        mode: Str(),
        parameter_name: Str(),
        edge_types: Arr(),
        risk_labels: Bool(),
        include_tests: Bool(),
        format: Str(),
        include_evidence: Bool(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "get_code_snippet",
      label: "Get Code Snippet",
      snippet: "Read source for a symbol by qualified_name",
      description:
        "Read source for a function or class. Pass qualified_name from search_graph.",
      properties: {
        project: Type.String(),
        qualified_name: Type.String(),
        include_neighbors: Bool(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "check_index_coverage",
      label: "Check Index Coverage",
      snippet: "Check whether paths are present in the graph index",
      description: "Validate graph coverage for candidate paths or directory scopes.",
      properties: {
        project: Type.String(),
        paths: Arr(),
        scopes: Arr(),
        scope_limit: Num(),
        scope_offset: Num(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "index_repository",
      label: "Index Repository",
      snippet: "Index a repository into the code knowledge graph",
      description: "Index a repository. Use an absolute repo_path.",
      guidelines: [
        "Call index_repository with an absolute repo_path when list_projects does not include the current repository.",
      ],
      properties: {
        repo_path: Type.String(),
        mode: Str(),
        target_projects: Arr(),
        name: Str(),
        persistence: Bool(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "index_status",
      label: "Index Status",
      snippet: "Show graph index health for a project",
      description: "Show index status for a project.",
      properties: {
        project: Type.String(),
        verbose: Bool(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "get_architecture",
      label: "Get Architecture",
      snippet: "Summarize project architecture from the graph",
      description: "High-level architecture summary from the knowledge graph.",
      properties: {
        project: Type.String(),
        path: Str(),
        aspects: Arr(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "query_graph",
      label: "Query Graph",
      snippet: "Run a Cypher query against the code graph",
      description: "Run a Cypher query for multi-hop graph patterns.",
      properties: {
        project: Type.String(),
        query: Type.String(),
        graph: Str(),
        max_rows: Num(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "search_code",
      label: "Search Code",
      snippet: "Graph-augmented text search over indexed source",
      description: "Search indexed source text. Prefer search_graph for symbols.",
      properties: {
        project: Type.String(),
        pattern: Type.String(),
        file_pattern: Str(),
        path_filter: Str(),
        mode: Str(),
        context: Num(),
        regex: Bool(),
        debug: Bool(),
        limit: Num(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "detect_changes",
      label: "Detect Changes",
      snippet: "Map the git diff to impacted graph symbols",
      description: "Map working-tree or ref diffs onto impacted symbols.",
      properties: {
        project: Type.String(),
        scope: Str(),
        direction: Str(),
        depth: Num(),
        limit: Num(),
        base_branch: Str(),
        since: Str(),
        format: Str(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "get_graph_schema",
      label: "Get Graph Schema",
      snippet: "Show node and edge types for a project graph",
      description: "Return node labels and edge types for the project graph.",
      properties: {
        project: Type.String(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "delete_project",
      label: "Delete Project",
      snippet: "Delete an indexed codebase-memory project",
      description: "Delete an indexed project from the local graph store.",
      properties: {
        project: Type.String(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "manage_adr",
      label: "Manage ADR",
      snippet: "Read or replace architecture decision records",
      description: "List ADR sections or replace the ADR document for a project.",
      properties: {
        project: Type.String(),
        mode: Str(),
        content: Str(),
      },
    }),
  );

  pi.registerTool(
    graphTool({
      name: "ingest_traces",
      label: "Ingest Traces",
      snippet: "Ingest execution traces into the project graph",
      description: "Ingest traces for a project.",
      properties: {
        project: Type.String(),
        traces: Type.Array(Type.Object({}, extra)),
      },
    }),
  );
}
