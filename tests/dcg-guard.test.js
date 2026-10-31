import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, mock, test } from "bun:test"
import * as childProcess from "node:child_process"
import { existsSync, lstatSync, mkdirSync, mkdtempSync, writeFileSync } from "node:fs"
import { mkdir, readdir, readFile, rm, writeFile } from "node:fs/promises"
import os from "node:os"
import path from "node:path"

import * as dcgGuardModule from "../profiles/base/plugins/dcg-guard.js"

const { default: dcgGuard, DcgGuard } = dcgGuardModule

// Some spawn results cannot be produced on demand, such as an I/O error after
// dcg started. Tests that need one set `spawnFault`; every other call, from the
// plugin or from this file, reaches the real spawnSync.
const realChildProcess = { ...childProcess }
const { spawnSync } = realChildProcess
let spawnFault = null
mock.module("node:child_process", () => ({
  ...realChildProcess,
  spawnSync: (...args) => (spawnFault ? spawnFault(...args) : spawnSync(...args)),
}))

// Fixture analyzers stand in for dcg at the subprocess boundary. They read the
// hook request and print canned output; none of them runs the command text.
// Each test starts from a minimal environment with no dcg on PATH, so neither a
// real dcg nor an operator's DCG_* settings can reach it.
const originalEnv = { ...process.env }
const sandbox = mkdtempSync(path.join(os.tmpdir(), "dcg-guard-"))
const bin = path.join(sandbox, "bin")
const emptyPath = path.join(sandbox, "empty-path")
mkdirSync(bin)
mkdirSync(emptyPath)
const ALLOW = `process.stdout.write(JSON.stringify({ dcg_verdict: "allow" }) + "\\n")`

let fixtures = 0

function replaceEnv(next) {
  for (const name of Object.keys(process.env)) if (!(name in next)) delete process.env[name]
  Object.assign(process.env, next)
}

beforeEach(() => {
  replaceEnv({ PATH: emptyPath, HOME: path.join(sandbox, "home") })
})

afterEach(() => {
  spawnFault = null
})

afterAll(async () => {
  replaceEnv(originalEnv)
  mock.module("node:child_process", () => realChildProcess)
  await rm(sandbox, { recursive: true, force: true })
})

// An executable stand-in for dcg: it consumes the request as `payload`, then runs `body`.
async function analyzer(body, name = `analyzer-${++fixtures}`, dir = bin) {
  const file = path.join(dir, name)
  await writeFile(file, [
    `#!${process.execPath}`,
    `import { writeFileSync } from "node:fs"`,
    `const chunks = []`,
    `for await (const chunk of process.stdin) chunks.push(chunk)`,
    `const payload = JSON.parse(Buffer.concat(chunks).toString("utf8"))`,
    `if (process.env.DCG_TEST_RECORD) writeFileSync(process.env.DCG_TEST_RECORD, JSON.stringify({ payload, opencode: process.env.OPENCODE }))`,
    body,
    "",
  ].join("\n"), { mode: 0o755 })
  return file
}

function hookOutput(permissionDecision, permissionDecisionReason) {
  const hookSpecificOutput = { hookEventName: "PreToolUse", permissionDecision }
  if (permissionDecisionReason !== undefined) hookSpecificOutput.permissionDecisionReason = permissionDecisionReason
  return JSON.stringify({ hookSpecificOutput })
}

function verdict(permissionDecision, permissionDecisionReason) {
  return `process.stdout.write(${JSON.stringify(hookOutput(permissionDecision, permissionDecisionReason))} + "\\n")`
}

// Runs the public hook the way OpenCode does: tool name in input.tool, command in output.args.
async function guard(command, { tool = "bash", args = { command } } = {}) {
  const warnings = []
  const consoleError = console.error
  console.error = (...parts) => warnings.push(parts.join(" "))
  try {
    const hooks = await DcgGuard({})
    await hooks["tool.execute.before"]?.({ tool, sessionID: "dcg-test", callID: "dcg-test" }, { args })
    return { allowed: true, warnings }
  } catch (error) {
    return { allowed: false, reason: error.message, warnings }
  } finally {
    console.error = consoleError
  }
}

describe("dcg-guard plugin", () => {
  test("exports one hook factory for modern and legacy loaders", async () => {
    expect(dcgGuard?.id).toBe("dcg-guard")
    expect(dcgGuard.server).toBe(DcgGuard)
    expect(typeof (await dcgGuard.server({}))["tool.execute.before"]).toBe("function")
  })

  test("sends the Bash command as a JSON hook request without a shell", async () => {
    const marker = path.join(sandbox, "shell-ran")
    const command = `pwd; touch "${marker}" && echo $(touch "${marker}")`
    const record = path.join(sandbox, "request.json")
    process.env.DCG_BIN = await analyzer(ALLOW)
    process.env.DCG_TEST_RECORD = record

    expect(await guard(command)).toEqual({ allowed: true, warnings: [] })
    expect(JSON.parse(await readFile(record, "utf8"))).toEqual({
      payload: { tool_name: "Bash", tool_input: { command }, dcg_explicit_verdict: true },
      opencode: "1",
    })
    expect(existsSync(marker)).toBe(false)
  })

  test("blocks deny and ask verdicts with the analyzer's full reason", async () => {
    process.env.DCG_BIN = await analyzer(verdict("deny", "fixture deny reason"))
    expect(await guard("pwd")).toMatchObject({ allowed: false, reason: "fixture deny reason" })

    // OpenCode has no review state to hand an `ask` to, so it cannot proceed.
    process.env.DCG_BIN = await analyzer(verdict("ask", "fixture ask reason"))
    expect(await guard("pwd")).toMatchObject({ allowed: false, reason: "fixture ask reason" })

    process.env.DCG_BIN = await analyzer(verdict("deny"))
    expect(await guard("pwd")).toMatchObject({ allowed: false, reason: "Blocked by dcg" })

    const long = `${"x".repeat(100000)} long reason tail`
    process.env.DCG_BIN = await analyzer(verdict("deny", long))
    expect(await guard("pwd")).toMatchObject({ allowed: false, reason: long })
  })

  test("leaves other tools and calls without a command unchecked", async () => {
    process.env.DCG_BIN = await analyzer(verdict("deny", "should not be asked"))
    expect((await guard("pwd", { tool: "read" })).allowed).toBe(true)
    expect((await guard(undefined, { args: {} })).allowed).toBe(true)
    expect((await guard(undefined, { args: undefined })).allowed).toBe(true)
    expect((await guard("")).allowed).toBe(true)
    expect((await guard(42)).allowed).toBe(true)
    expect((await guard("pwd")).allowed).toBe(false)
  })

  test("blocks a started analyzer that gives no usable verdict", async () => {
    const outputs = {
      empty: "",
      "not JSON": `process.stdout.write("allow\\n")`,
      "unknown verdict": `process.stdout.write(JSON.stringify({ dcg_verdict: "maybe" }))`,
      "JSON null": `process.stdout.write("null")`,
      "hook allow without explicit verdict": verdict("allow"),
      "two verdict lines": `${ALLOW}; ${ALLOW}`,
    }
    for (const [label, body] of Object.entries(outputs)) {
      process.env.DCG_BIN = await analyzer(body)
      const result = await guard("pwd")
      expect({ label, allowed: result.allowed }).toEqual({ label, allowed: false })
      expect(result.reason).toContain("gave no verdict")
    }
  })

  test("blocks nonzero exits and signals with a bounded diagnostic", async () => {
    process.env.DCG_BIN = await analyzer(`${ALLOW}; process.stderr.write("x".repeat(20000) + "stderr tail"); process.exit(2)`)
    const exited = await guard("pwd")
    expect(exited.allowed).toBe(false)
    expect(exited.reason).toContain("exited 2")
    expect(exited.reason).toContain("stderr tail")
    expect(exited.reason.length).toBeLessThan(1000)

    process.env.DCG_BIN = await analyzer(`${ALLOW}; process.kill(process.pid, "SIGKILL")`)
    const killed = await guard("pwd")
    expect(killed.allowed).toBe(false)
    expect(killed.reason).toContain("SIGKILL")
  })

  test("stops the analyzer after ten seconds even when it ignores SIGTERM", async () => {
    process.env.DCG_BIN = await analyzer(`process.on("SIGTERM", () => {}); ${ALLOW}; setTimeout(() => {}, 60000)`)
    const started = Date.now()
    const result = await guard("pwd")
    const elapsed = Date.now() - started
    expect(result.allowed).toBe(false)
    expect(result.reason).toContain("timed out")
    expect(elapsed).toBeGreaterThanOrEqual(9000)
    expect(elapsed).toBeLessThan(15000)
  }, 30000)

  test("an explicit deny or ask wins over a later analyzer failure and the crash override", async () => {
    process.env.DCG_BIN = await analyzer(`${verdict("deny", "denied before crash")}; process.exit(3)`)
    expect(await guard("pwd")).toMatchObject({ allowed: false, reason: "denied before crash" })

    process.env.DCG_BRIDGE_CRASH_DECISION = "allow"
    expect(await guard("pwd")).toMatchObject({ allowed: false, reason: "denied before crash" })

    process.env.DCG_BIN = await analyzer(`${verdict("ask", "ask before crash")}; process.kill(process.pid, "SIGKILL")`)
    expect(await guard("pwd")).toMatchObject({ allowed: false, reason: "ask before crash" })
  })

  test("DCG_BRIDGE_CRASH_DECISION=allow lets failed analysis through with a warning", async () => {
    process.env.DCG_BIN = await analyzer(`process.exit(1)`)
    process.env.DCG_BRIDGE_CRASH_DECISION = " Allow "
    const allowed = await guard("pwd")
    expect(allowed.allowed).toBe(true)
    expect(allowed.warnings.join("\n")).toContain("DCG_BRIDGE_CRASH_DECISION=allow")

    process.env.DCG_BRIDGE_CRASH_DECISION = "deny"
    expect((await guard("pwd")).allowed).toBe(false)
  })

  test("DCG_BYPASS accepts dcg's true spellings and nothing else", async () => {
    process.env.DCG_BIN = await analyzer(verdict("deny", "not bypassed"))
    for (const value of ["1", "true", " YES ", "y", "On"]) {
      process.env.DCG_BYPASS = value
      expect({ value, allowed: (await guard("pwd")).allowed }).toEqual({ value, allowed: true })
    }
    for (const value of ["0", "false", "no", "", "enabled"]) {
      process.env.DCG_BYPASS = value
      expect({ value, allowed: (await guard("pwd")).allowed }).toEqual({ value, allowed: false })
    }
  })

  test("fails open with a warning when the analyzer cannot start", async () => {
    process.env.DCG_BIN = path.join(sandbox, "missing-dcg")
    const missing = await guard("pwd")
    expect(missing.allowed).toBe(true)
    expect(missing.warnings.join("\n")).toContain("could not start dcg")

    const notExecutable = path.join(sandbox, "not-executable-dcg")
    await writeFile(notExecutable, "#!/bin/sh\n", { mode: 0o644 })
    process.env.DCG_BIN = notExecutable
    const unstartable = await guard("pwd")
    expect(unstartable.allowed).toBe(true)
    expect(unstartable.warnings.join("\n")).toContain("could not start dcg")
  })

  test("resolves dcg from PATH when DCG_BIN is unset", async () => {
    const pathDir = path.join(sandbox, "path-bin")
    await mkdir(pathDir)
    await analyzer(verdict("deny", "found on PATH"), "dcg", pathDir)
    process.env.PATH = pathDir
    expect(await guard("pwd")).toMatchObject({ allowed: false, reason: "found on PATH" })

    process.env.PATH = emptyPath
    const missing = await guard("pwd")
    expect(missing.allowed).toBe(true)
    expect(missing.warnings.join("\n")).toContain("could not start dcg")
  })
})

// Spawn results without an exit status or signal. Node reports the missing
// status as null and Bun as undefined. Only ENOENT and EACCES show that dcg was
// never started; Bun reports other I/O failures with the same shape after dcg
// has already run.
describe("dcg-guard spawn errors without an exit status", () => {
  function spawnError(code, { status, stdout = null } = {}) {
    const error = Object.assign(new Error(`spawnSync dcg ${code ?? "failed"}`), code ? { code } : {})
    return () => ({ pid: 0, output: [null, stdout, null], stdout, stderr: null, status, signal: null, error })
  }

  test("only a missing or non-executable dcg fails open", async () => {
    process.env.DCG_BIN = path.join(sandbox, "mocked-dcg")
    for (const status of [null, undefined]) {
      for (const code of ["ENOENT", "EACCES"]) {
        spawnFault = spawnError(code, { status })
        expect(spawnFault().status).toBe(status)
        const result = await guard("pwd")
        expect({ code, status, allowed: result.allowed }).toEqual({ code, status, allowed: true })
        expect(result.warnings.join("\n")).toContain("could not start dcg")
      }
      for (const code of ["EIO", "ENOMEM", "ENOBUFS", "EPIPE", "EAGAIN", undefined]) {
        spawnFault = spawnError(code, { status })
        expect(spawnFault().status).toBe(status)
        const result = await guard("pwd")
        expect({ code, status, allowed: result.allowed }).toEqual({ code, status, allowed: false })
        expect(result.reason).toContain("gave no verdict")
      }
    }
  })

  test("DCG_BRIDGE_CRASH_DECISION=allow lets an unclassified spawn error through with a warning", async () => {
    process.env.DCG_BIN = path.join(sandbox, "mocked-dcg")
    process.env.DCG_BRIDGE_CRASH_DECISION = "allow"
    spawnFault = spawnError("EIO", { status: undefined })
    expect(spawnFault().status).toBeUndefined()
    const result = await guard("pwd")
    expect(result.allowed).toBe(true)
    expect(result.warnings.join("\n")).toContain("DCG_BRIDGE_CRASH_DECISION=allow")
  })

  test("a deny or ask on stdout wins over any spawn error and the crash override", async () => {
    process.env.DCG_BIN = path.join(sandbox, "mocked-dcg")
    process.env.DCG_BRIDGE_CRASH_DECISION = "allow"
    for (const [decision, code] of [["deny", "ENOENT"], ["ask", "EACCES"], ["deny", "EIO"], ["ask", undefined]]) {
      spawnFault = spawnError(code, { stdout: `${hookOutput(decision, `${decision} despite ${code}`)}\n` })
      expect(await guard("pwd")).toMatchObject({ allowed: false, reason: `${decision} despite ${code}` })
    }
  })
})

// The installed dcg, found from the original DCG_BIN or PATH. Protocol baseline:
// v0.15.2 (explicit verdict mode).
const realBinary = originalEnv.DCG_BIN || Bun.which("dcg", { PATH: originalEnv.PATH ?? "" })

function realDcgPreflight(systemConfig = "/etc/dcg/config.toml", inspect = lstatSync) {
  try {
    inspect(systemConfig)
    return `uncontrolled dcg system config exists: ${systemConfig}`
  } catch (error) {
    if (error.code === "ENOENT") return null
    return `cannot establish dcg system-config absence: ${systemConfig} (${error.code ?? error.message})`
  }
}

function checkedRealProbe(probe, systemConfig, inspect) {
  const gap = realDcgPreflight(systemConfig, inspect)
  if (gap) throw new Error(gap)
  return probe()
}

describe("real dcg system-config preflight", () => {
  test("runs a probe only when the system config is absent", () => {
    const config = path.join(sandbox, "system-config.toml")
    let probes = 0
    const probe = () => ++probes
    expect(checkedRealProbe(probe, config)).toBe(1)
    writeFileSync(config, "")
    expect(() => checkedRealProbe(probe, config)).toThrow("system config exists")
    expect(probes).toBe(1)
  })

  test("refuses a probe when system-config absence cannot be established", () => {
    let probes = 0
    const inspect = () => { throw Object.assign(new Error("permission denied"), { code: "EACCES" }) }
    expect(() => checkedRealProbe(() => ++probes, "/scratch/config.toml", inspect)).toThrow("cannot establish")
    expect(probes).toBe(0)
  })
})

// Controlled environment for qualified hosts: dcg also merges the POSIX
// /etc/dcg/config.toml, so every native probe first requires its absence.
// No operator environment is inherited; configured state paths stay in root.
function isolatedDcgEnv(root) {
  const home = path.join(root, "home")
  return {
    PATH: "/usr/bin:/bin",
    HOME: home,
    XDG_CONFIG_HOME: path.join(home, ".config"),
    XDG_DATA_HOME: path.join(home, ".local/share"),
    XDG_CACHE_HOME: path.join(home, ".cache"),
    XDG_STATE_HOME: path.join(home, ".local/state"),
    DCG_CONFIG: path.join(root, "config.toml"),
    DCG_ALLOWLIST_SYSTEM_PATH: path.join(root, "system-allowlist.toml"),
    DCG_HISTORY_DB: path.join(root, "history.db"),
    DCG_PENDING_EXCEPTIONS_PATH: path.join(root, "pending.jsonl"),
    DCG_ALLOW_ONCE_PATH: path.join(root, "allow-once.jsonl"),
    DCG_NO_UPDATE_CHECK: "1",
    DCG_NO_SELF_HEAL: "1",
  }
}

function realDcgGap() {
  const systemGap = realDcgPreflight()
  if (systemGap) return systemGap
  if (!realBinary) return "dcg is not on PATH and DCG_BIN is unset"
  const root = path.join(sandbox, "dcg-version")
  mkdirSync(path.join(root, "home"), { recursive: true })
  writeFileSync(path.join(root, "config.toml"), "")
  const result = checkedRealProbe(() => spawnSync(realBinary, ["--version"], { encoding: "utf8", timeout: 10000, killSignal: "SIGKILL", cwd: root, env: isolatedDcgEnv(root) }))
  const match = /(\d+)\.(\d+)\.(\d+)/.exec(`${result.stdout}`)
  if (!match) return `could not read a version from ${realBinary} --version`
  const [major, minor, patch] = match.slice(1).map(Number)
  if (major === 0 && (minor < 15 || (minor === 15 && patch < 2))) return `dcg ${match[0]} predates the v0.15.2 protocol baseline`
  return null
}

const gap = realDcgGap()
if (gap) console.warn(`[dcg-guard.test] skipped the installed-dcg probe: ${gap}`)

describe.skipIf(Boolean(gap))("installed dcg protocol", () => {
  const inner = path.join(sandbox, "real-dcg")
  const sentinel = path.join(sandbox, "sentinel")

  // Settings an operator might export. Honoring the allowlist would let
  // `git reset --hard` through; honoring the others would write into `sentinel`.
  function inheritedSettings() {
    const home = path.join(sentinel, "home")
    return {
      PATH: "/usr/bin:/bin",
      HOME: home,
      XDG_CONFIG_HOME: path.join(home, ".config"),
      XDG_STATE_HOME: path.join(home, ".local/state"),
      DCG_CONFIG: path.join(sentinel, "config.toml"),
      DCG_ALLOWLIST_SYSTEM_PATH: path.join(sentinel, "allowlist.toml"),
      DCG_HISTORY_DB: path.join(sentinel, "history.db"),
      DCG_PENDING_EXCEPTIONS_PATH: path.join(sentinel, "pending.jsonl"),
      DCG_ALLOW_ONCE_PATH: path.join(sentinel, "allow-once.jsonl"),
      DCG_NO_UPDATE_CHECK: "1",
      DCG_NO_SELF_HEAL: "1",
    }
  }

  async function sentinelFiles() {
    return (await readdir(sentinel, { recursive: true })).sort()
  }

  function rawProbe(command, env = isolatedDcgEnv(inner)) {
    const input = JSON.stringify({ tool_name: "Bash", tool_input: { command }, dcg_explicit_verdict: true })
    return checkedRealProbe(() => spawnSync(realBinary, { input, encoding: "utf8", timeout: 10000, killSignal: "SIGKILL", cwd: inner, env: { ...env, OPENCODE: "1" } }))
  }

  // The plugin passes its whole environment to dcg, so the hook runs with
  // process.env swapped for the isolated one.
  async function hookProbe(command) {
    const inherited = { ...process.env }
    const previous = process.cwd()
    replaceEnv({ ...isolatedDcgEnv(inner), DCG_BIN: realBinary })
    process.chdir(inner)
    try {
      return await checkedRealProbe(() => guard(command))
    } finally {
      process.chdir(previous)
      replaceEnv(inherited)
    }
  }

  beforeAll(async () => {
    await mkdir(path.join(inner, "home"), { recursive: true })
    await writeFile(path.join(inner, "config.toml"), "")
    await mkdir(sentinel)
    await writeFile(path.join(sentinel, "config.toml"), `[general]\nlog_file = ${JSON.stringify(path.join(sentinel, "blocked.log"))}\n`)
    await writeFile(path.join(sentinel, "allowlist.toml"), `[[allow]]\nrule = "core.git:reset-hard"\nreason = "sentinel"\n`)
  })

  beforeEach(() => {
    replaceEnv({ ...inheritedSettings(), DCG_BIN: realBinary })
  })

  test("returns an explicit allow and a deny for command text it only analyzes", async () => {
    const raw = rawProbe("pwd")
    expect(raw.status).toBe(0)
    expect(JSON.parse(raw.stdout)).toEqual({ dcg_verdict: "allow" })

    expect(await hookProbe("pwd")).toEqual({ allowed: true, warnings: [] })
    const denied = await hookProbe("git reset --hard")
    expect(denied.allowed).toBe(false)
    expect(denied.reason).toContain("git reset --hard")
    // dcg recorded the blocked command inside the isolated sandbox.
    const pending = JSON.parse((await readFile(path.join(inner, "pending.jsonl"), "utf8")).trim().split("\n").at(-1))
    expect(pending.command_raw).toBe("git reset --hard")
  })

  test("inherited dcg settings neither change a verdict nor receive a write", async () => {
    const planted = await sentinelFiles()
    expect(realDcgGap()).toBeNull()
    expect(JSON.parse(rawProbe("git reset --hard").stdout).hookSpecificOutput.permissionDecision).toBe("deny")
    expect((await hookProbe("git reset --hard")).allowed).toBe(false)
    expect(await sentinelFiles()).toEqual(planted)

    // Control: passed straight to dcg, the same settings do take effect.
    expect(JSON.parse(rawProbe("git reset --hard", inheritedSettings()).stdout)).toEqual({ dcg_verdict: "allow" })
    const { DCG_ALLOWLIST_SYSTEM_PATH, ...withoutAllowlist } = inheritedSettings()
    expect(JSON.parse(rawProbe("git reset --hard", withoutAllowlist).stdout).hookSpecificOutput.permissionDecision).toBe("deny")
    expect(await sentinelFiles()).toEqual(expect.arrayContaining([...planted, "blocked.log", "pending.jsonl"]))
  })
})
