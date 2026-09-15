import { spawnSync } from "node:child_process";

function paseo(event) {
  if (!process.env.PASEO_TERMINAL_ID) {
    return;
  }
  const cli = process.env.PASEO_HOOK_CLI || "paseo";
  spawnSync(cli, ["hooks", "pi", event], {
    timeout: 10000,
    stdio: "ignore",
  });
}

export default function (pi) {
  pi.on("session_start", () => paseo("SessionStart"));
  pi.on("input", () => paseo("UserPromptSubmit"));
  pi.on("tool_execution_start", () => paseo("PreToolUse"));
  pi.on("tool_execution_end", () => paseo("PostToolUse"));
  pi.on("agent_end", () => paseo("Stop"));
  pi.on("session_shutdown", () => paseo("SessionEnd"));
}
