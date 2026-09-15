import {
  createBashToolDefinition,
  createEditToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const BUILTINS = ["read", "bash", "edit", "write", "grep", "find", "ls"];
const CLAUDE_ALIASES = ["Read", "Edit", "Write", "Bash", "Grep", "Glob", "LS"];
const GRAPH_TOOLS = [
  "index_repository",
  "search_graph",
  "query_graph",
  "trace_path",
  "get_code_snippet",
  "get_graph_schema",
  "get_architecture",
  "search_code",
  "list_projects",
  "delete_project",
  "index_status",
  "check_index_coverage",
  "detect_changes",
  "manage_adr",
  "ingest_traces",
];
const MANAGED = new Set([...BUILTINS, ...CLAUDE_ALIASES, "bash_ide", "bash_ide_ide"]);
const originalArrayFind = Array.prototype.find;
const IDE_SUFFIX_LIMIT = 24;

function modelBlob(model) {
  if (!model) return "";
  if (typeof model === "string") return model.toLowerCase();
  return [model.provider, model.id, model.name].filter(Boolean).join(" ").toLowerCase();
}

function isClaude(model) {
  const text = modelBlob(model);
  return text.includes("claude") || text.includes("anthropic");
}

function filePath(params) {
  return params?.path || params?.file_path || params?.filePath || "";
}

function isToolArray(value) {
  return Array.isArray(value) && value.length > 0 && typeof value[0]?.name === "string";
}

function ideNameCandidates(toolName) {
  const names = new Set();
  for (const base of [toolName, toolName.toLowerCase()]) {
    let alias = base;
    for (let i = 0; i < IDE_SUFFIX_LIMIT; i++) {
      alias = `${alias}_ide`;
      names.add(alias);
    }
  }
  return names;
}

function coerceIdeArgs(args) {
  if (!args || typeof args !== "object" || Array.isArray(args)) return args;
  const next = { ...args };
  if (typeof next.queries === "string") next.queries = [next.queries];
  if (typeof next.query === "string" && next.queries === undefined) next.queries = [next.query];
  if (!next.path && (next.file_path || next.filePath)) next.path = next.file_path || next.filePath;
  return next;
}

function wrapToolForIdeArgs(tool) {
  return {
    ...tool,
    prepareArguments(args) {
      const coerced = coerceIdeArgs(args);
      return typeof tool.prepareArguments === "function" ? tool.prepareArguments(coerced) : coerced;
    },
  };
}

// Pi resolves calls with tools.find(t => t.name === call.name). Claude/Paseo appends
// `_ide` (repeatedly) to the name from the previous turn. Match those aliases here;
// never advertise `*_ide` names or the model keeps stacking suffixes.
function ideFind(predicate, thisArg) {
  const found = originalArrayFind.call(this, predicate, thisArg);
  if (found !== undefined) return wrapToolForIdeArgs(found);
  if (typeof predicate !== "function" || !isToolArray(this)) return found;
  for (const tool of this) {
    if (typeof tool?.name !== "string") continue;
    for (const alias of ideNameCandidates(tool.name)) {
      if (predicate.call(thisArg, { ...tool, name: alias })) return wrapToolForIdeArgs(tool);
    }
  }
  return found;
}

function setIdeAliasPatch(enabled) {
  Array.prototype.find = enabled ? ideFind : originalArrayFind;
}

function advertisedTools(pi, model) {
  const extra = pi
    .getActiveTools()
    .filter((name) => !MANAGED.has(name) && !name.endsWith("_ide"));
  const names = [...extra, ...BUILTINS, ...GRAPH_TOOLS];
  if (isClaude(model)) names.push(...CLAUDE_ALIASES);
  return [...new Set(names)];
}

export default function (pi) {
  setIdeAliasPatch(true);

  pi.registerTool({
    name: "Read",
    label: "Read",
    description: "Read a file from the local filesystem.",
    parameters: Type.Object({
      path: Type.Optional(Type.String()),
      file_path: Type.Optional(Type.String()),
      offset: Type.Optional(Type.Number()),
      limit: Type.Optional(Type.Number()),
    }),
    async execute(id, params, signal, onUpdate, ctx) {
      return createReadToolDefinition(ctx.cwd).execute(
        id,
        { path: filePath(params), offset: params.offset, limit: params.limit },
        signal,
        onUpdate,
        ctx,
      );
    },
  });

  pi.registerTool({
    name: "Write",
    label: "Write",
    description: "Write a file to the local filesystem.",
    parameters: Type.Object({
      path: Type.Optional(Type.String()),
      file_path: Type.Optional(Type.String()),
      content: Type.String(),
    }),
    async execute(id, params, signal, onUpdate, ctx) {
      return createWriteToolDefinition(ctx.cwd).execute(
        id,
        { path: filePath(params), content: params.content ?? "" },
        signal,
        onUpdate,
        ctx,
      );
    },
  });

  pi.registerTool({
    name: "Edit",
    label: "Edit",
    description: "Edit a file by replacing exact text.",
    parameters: Type.Object({
      path: Type.Optional(Type.String()),
      file_path: Type.Optional(Type.String()),
      old_string: Type.Optional(Type.String()),
      new_string: Type.Optional(Type.String()),
      oldText: Type.Optional(Type.String()),
      newText: Type.Optional(Type.String()),
    }),
    async execute(id, params, signal, onUpdate, ctx) {
      return createEditToolDefinition(ctx.cwd).execute(
        id,
        {
          path: filePath(params),
          edits: [
            {
              oldText: params.old_string ?? params.oldText ?? "",
              newText: params.new_string ?? params.newText ?? "",
            },
          ],
        },
        signal,
        onUpdate,
        ctx,
      );
    },
  });

  pi.registerTool({
    name: "Bash",
    label: "Bash",
    description: "Run a shell command.",
    parameters: Type.Object({
      command: Type.String(),
      timeout: Type.Optional(Type.Number()),
    }),
    async execute(id, params, signal, onUpdate, ctx) {
      return createBashToolDefinition(ctx.cwd).execute(
        id,
        { command: params.command, timeout: params.timeout },
        signal,
        onUpdate,
        ctx,
      );
    },
  });

  pi.registerTool({
    name: "Grep",
    label: "Grep",
    description: "Search file contents with ripgrep.",
    parameters: Type.Object({
      pattern: Type.String(),
      path: Type.Optional(Type.String()),
      glob: Type.Optional(Type.String()),
    }),
    async execute(id, params, signal, onUpdate, ctx) {
      return createGrepToolDefinition(ctx.cwd).execute(id, params, signal, onUpdate, ctx);
    },
  });

  pi.registerTool({
    name: "Glob",
    label: "Glob",
    description: "Find files by glob pattern.",
    parameters: Type.Object({
      pattern: Type.String(),
      path: Type.Optional(Type.String()),
    }),
    async execute(id, params, signal, onUpdate, ctx) {
      return createFindToolDefinition(ctx.cwd).execute(id, params, signal, onUpdate, ctx);
    },
  });

  pi.registerTool({
    name: "LS",
    label: "LS",
    description: "List files in a directory.",
    parameters: Type.Object({
      path: Type.Optional(Type.String()),
    }),
    async execute(id, params, signal, onUpdate, ctx) {
      return createLsToolDefinition(ctx.cwd).execute(id, params, signal, onUpdate, ctx);
    },
  });

  function apply(model) {
    setIdeAliasPatch(true);
    pi.setActiveTools(advertisedTools(pi, model));
  }

  pi.on("session_start", (_event, ctx) => {
    apply(ctx.model);
  });

  pi.on("model_select", (event) => {
    apply(event.model);
  });

  pi.on("session_shutdown", () => {
    setIdeAliasPatch(false);
  });
}
