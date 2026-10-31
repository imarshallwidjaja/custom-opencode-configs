// OpenCode plugin adapter for dcg (Destructive Command Guard).
// https://github.com/Dicklesworthstone/destructive_command_guard
//
// Before each bash tool call, sends the command to dcg as a Claude Code
// PreToolUse hook request on stdin, with dcg_explicit_verdict so that dcg
// answers {"dcg_verdict":"allow"} instead of an empty stdout. dcg v0.15.2 is
// the oldest release this protocol was checked against. dcg only analyzes the
// command text; this plugin never runs it through a shell.
//
// This file is owned by this repository. `dcg install --opencode` and
// `dcg update` may write their own plugins/dcg-guard.js over it; reinstall the
// profile and run `bun test tests/dcg-guard.test.js` after either.
//
// node:child_process works under both Node and Bun.
import { spawnSync } from "node:child_process";

const TIMEOUT_MS = 10000;
const MAX_STDERR = 500;
// Spawn errors that mean dcg was never started: it is missing or not
// executable. Bun reports other errors, such as EIO, with the same empty status
// even after dcg ran, so those are failures, not a missing install.
const NOT_STARTED = new Set(["ENOENT", "EACCES"]);

// dcg's own boolean spelling for environment flags.
function envFlag(name) {
  const value = process.env[name];
  return typeof value === "string" && ["1", "true", "yes", "y", "on"].includes(value.trim().toLowerCase());
}

// dcg gave no verdict: it was killed (a signal, or this plugin's timeout),
// exited non-zero, failed with any other spawn error, or did not print its
// explicit allow. That is not an allow. Block, unless the operator opted out with
// DCG_BRIDGE_CRASH_DECISION=allow.
function noVerdict(detail) {
  const setting = process.env.DCG_BRIDGE_CRASH_DECISION;
  if (typeof setting === "string" && setting.trim().toLowerCase() === "allow") {
    console.error(`[dcg] OpenCode guard got no verdict from dcg (${detail}); allowed because DCG_BRIDGE_CRASH_DECISION=allow`);
    return null;
  }
  console.error(`[dcg] OpenCode guard got no verdict from dcg (${detail}); blocking`);
  return `Blocked by dcg: the command could not be verified because dcg gave no verdict (${detail}). Set DCG_BRIDGE_CRASH_DECISION=allow to let commands through when dcg fails.`;
}

// Returns a block reason, or null to allow. Apart from a deny or ask verdict,
// which always blocks, only a dcg that could not be started at all (missing or
// not executable) fails open, with a warning, so that a missing install does
// not block every command.
function dcgBlockReason(command) {
  if (typeof command !== "string" || command.length === 0) return null;
  // dcg's escape hatch exits before reading its input, so it never answers.
  if (envFlag("DCG_BYPASS")) return null;
  const binary = process.env.DCG_BIN || "dcg";
  const result = spawnSync(binary, {
    input: JSON.stringify({ tool_name: "Bash", tool_input: { command }, dcg_explicit_verdict: true }),
    encoding: "utf8",
    env: { ...process.env, OPENCODE: "1" },
    timeout: TIMEOUT_MS,
    // SIGTERM can be ignored; the timeout has to end the analyzer.
    killSignal: "SIGKILL",
  });
  // stdout is untrusted: accept exactly one JSON object and check field types.
  const text = typeof result.stdout === "string" ? result.stdout.trim() : "";
  let decision = null;
  try {
    decision = text ? JSON.parse(text) : null;
  } catch {
    decision = null;
  }
  if (!decision || typeof decision !== "object" || Array.isArray(decision)) decision = null;
  const hso = decision && decision.hookSpecificOutput && typeof decision.hookSpecificOutput === "object" ? decision.hookSpecificOutput : {};
  // OpenCode has no review state to hand `ask` to, so it blocks like `deny`.
  // A blocking verdict stands whatever the spawn result says about the process.
  if (hso.permissionDecision === "deny" || hso.permissionDecision === "ask") {
    return typeof hso.permissionDecisionReason === "string" && hso.permissionDecisionReason ? hso.permissionDecisionReason : "Blocked by dcg";
  }

  // Never started: Node reports status null, Bun leaves it undefined.
  if (result.error && NOT_STARTED.has(result.error.code) && result.status == null && !result.signal) {
    console.error(`[dcg] OpenCode guard could not start dcg (${result.error.message}); allowing the command unchecked. Put dcg on PATH or set DCG_BIN.`);
    return null;
  }

  const stderr = typeof result.stderr === "string" ? result.stderr.trim().slice(-MAX_STDERR) : "";
  const tail = stderr ? `: ${stderr}` : "";
  if (result.signal) {
    const timedOut = result.error && result.error.code === "ETIMEDOUT" ? `, timed out after ${TIMEOUT_MS / 1000}s` : "";
    return noVerdict(`dcg was killed by ${result.signal}${timedOut}${tail}`);
  }
  if (result.error) return noVerdict(`dcg failed: ${result.error.message}${tail}`);
  if (result.status !== 0) return noVerdict(`dcg exited ${result.status}${tail}`);
  if (!text) return noVerdict(`dcg exited 0 with nothing on stdout${tail}`);
  if (decision && decision.dcg_verdict === "allow") return null;
  return noVerdict("dcg stdout was not a verdict");
}

// Hook factory for loaders that call exported functions (OpenCode plugin v1).
export const DcgGuard = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (!input || input.tool !== "bash") return;
      const reason = dcgBlockReason(output?.args?.command);
      if (reason) throw new Error(reason);
    },
  };
};

// Loaders that read a default { id, server } module get the same hooks.
export default {
  id: "dcg-guard",
  server: DcgGuard,
};
