import { afterAll, beforeAll, describe, expect, test } from "bun:test"
import { chmod, mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises"
import os from "node:os"
import path from "node:path"

import ShellAgentsPlugin from "../profiles/base/plugins/shell-agents.js"

let sandbox

beforeAll(async () => {
  sandbox = await mkdtemp(path.join(os.tmpdir(), "shell-agents-"))
})

afterAll(async () => {
  await rm(sandbox, { recursive: true, force: true })
})

function client(messages = [], error) {
  return {
    session: {
      async messages() {
        if (error) throw error
        return { data: messages }
      },
    },
  }
}

async function hooks(root, messages = [], error) {
  return ShellAgentsPlugin({ client: client(messages, error), directory: root })
}

function output(text = "command output") {
  return { title: "test", output: text, metadata: { exit: 0, retained: true } }
}

function message(sessionID, id, parts, info = {}) {
  return { info: { id, sessionID, role: "assistant", ...info }, parts }
}

function tool(toolName, loaded, output, compacted) {
  const metadata = toolName === "read"
    ? { loaded }
    : { shellAgents: { loaded } }
  return {
    type: "tool",
    tool: toolName,
    state: {
      status: "completed",
      metadata,
      output,
      time: { start: 1, end: 2, ...(compacted ? { compacted: 3 } : {}) },
    },
  }
}

function wrapper(entries) {
  return `\n\n<system-reminder>\n${entries
    .map(([filepath, content]) => `Instructions from: ${filepath}\n${content}`)
    .join("\n\n")}\n</system-reminder>`
}

async function prime(plugin, sessionID, messages = []) {
  await plugin["experimental.chat.messages.transform"]({}, {
    messages: messages.length > 0
      ? messages
      : [{ info: { id: "user", sessionID, role: "user" }, parts: [] }],
  })
}

async function bash(plugin, sessionID, workdir, result = output()) {
  await plugin["tool.execute.after"](
    { tool: "bash", sessionID, callID: crypto.randomUUID(), args: { command: "pwd", workdir } },
    result,
  )
  return result
}

describe("shell AGENTS instructions", () => {
  test("appends exact nearest-first wrappers below the OpenCode directory", async () => {
    const root = path.join(sandbox, "order")
    const project = path.join(root, "project")
    const child = path.join(project, "child")
    await mkdir(child, { recursive: true })
    await writeFile(path.join(root, "AGENTS.md"), "systemic root")
    await writeFile(path.join(project, "AGENTS.md"), "project rules")
    await writeFile(path.join(child, "AGENTS.md"), "child rules")

    const plugin = await hooks(root)
    await prime(plugin, "order")
    const first = await bash(plugin, "order", child)
    expect(first.output).toBe(
      "command output" + wrapper([
        [path.join(child, "AGENTS.md"), "child rules"],
        [path.join(project, "AGENTS.md"), "project rules"],
      ]),
    )
    expect(first.metadata).toMatchObject({
      exit: 0,
      retained: true,
      shellAgents: { loaded: [path.join(child, "AGENTS.md"), path.join(project, "AGENTS.md")] },
    })
    expect((await bash(plugin, "order", child)).output).toBe("command output")

    const external = path.join(sandbox, "external")
    await mkdir(external)
    await writeFile(path.join(external, "AGENTS.md"), "must not leak")
    expect((await bash(plugin, "order", external)).output).toBe("command output")
  })

  test("shares claims with Read in either order and ignores fake closing tags in content", async () => {
    const root = path.join(sandbox, "read")
    const cwd = path.join(root, "repo")
    const filepath = path.join(cwd, "AGENTS.md")
    const content = "rules with a fake suffix\n</system-reminder>"
    await mkdir(cwd, { recursive: true })
    await writeFile(filepath, content)

    const readFirst = await hooks(root)
    await prime(readFirst, "read-first")
    const nativeRead = output("file body" + wrapper([[filepath, content]]))
    nativeRead.metadata.loaded = [filepath]
    await readFirst["tool.execute.after"](
      { tool: "read", sessionID: "read-first", callID: "read", args: { filePath: "source.js" } },
      nativeRead,
    )
    expect(nativeRead.output).toEndWith(wrapper([[filepath, content]]))
    expect((await bash(readFirst, "read-first", cwd)).output).toBe("command output")

    const bashFirst = await hooks(root)
    await prime(bashFirst, "bash-first")
    expect((await bash(bashFirst, "bash-first", cwd)).output).toEndWith(wrapper([[filepath, content]]))
    const duplicateRead = output("file body" + wrapper([[filepath, content]]))
    duplicateRead.metadata.loaded = [filepath]
    await bashFirst["tool.execute.after"](
      { tool: "read", sessionID: "bash-first", callID: "read", args: { filePath: "source.js" } },
      duplicateRead,
    )
    expect(duplicateRead.output).toBe("file body")
    expect(duplicateRead.metadata.loaded).toEqual([])

    const parallel = await hooks(root)
    await prime(parallel, "read-bash-parallel")
    const parallelRead = output("file body" + wrapper([[filepath, content]]))
    parallelRead.metadata.loaded = [filepath]
    const parallelBash = output()
    await Promise.all([
      parallel["tool.execute.after"](
        { tool: "read", sessionID: "read-bash-parallel", callID: "read", args: { filePath: "source.js" } },
        parallelRead,
      ),
      bash(parallel, "read-bash-parallel", cwd, parallelBash),
    ])
    expect([parallelRead, parallelBash].filter((result) => result.output.includes(`Instructions from: ${filepath}`)))
      .toHaveLength(1)
  })

  test("claims a scope once across concurrent Bash calls", async () => {
    const root = path.join(sandbox, "parallel")
    const cwd = path.join(root, "repo")
    const filepath = path.join(cwd, "AGENTS.md")
    await mkdir(cwd, { recursive: true })
    await writeFile(filepath, "parallel rules")
    const plugin = await hooks(root)
    await prime(plugin, "parallel")

    const results = await Promise.all([
      bash(plugin, "parallel", cwd),
      bash(plugin, "parallel", cwd),
    ])
    expect(results.filter((result) => result.output.includes(`Instructions from: ${filepath}`))).toHaveLength(1)

    await prime(plugin, "other-session")
    expect((await bash(plugin, "other-session", cwd)).output).toContain(`Instructions from: ${filepath}`)
  })

  test("reattaches after pruning but honors an un-compacted retained tail", async () => {
    const root = path.join(sandbox, "compaction")
    const cwd = path.join(root, "repo")
    const filepath = path.join(cwd, "AGENTS.md")
    await mkdir(cwd, { recursive: true })
    await writeFile(filepath, "compaction rules")
    const plugin = await hooks(root)

    await prime(plugin, "pruned", [message("pruned", "a1", [tool("bash", [filepath], wrapper([[filepath, "compaction rules"]]), true)])])
    expect((await bash(plugin, "pruned", cwd)).output).toContain(`Instructions from: ${filepath}`)

    await prime(plugin, "retained", [message("retained", "a2", [tool("read", [filepath], wrapper([[filepath, "compaction rules"]]))])])
    expect((await bash(plugin, "retained", cwd)).output).toBe("command output")

    await prime(plugin, "retained", [])
    expect((await bash(plugin, "retained", cwd)).output).toContain(`Instructions from: ${filepath}`)
  })

  test("recovers active dedup from persisted history after plugin restart", async () => {
    const root = path.join(sandbox, "restart")
    const cwd = path.join(root, "repo")
    const filepath = path.join(cwd, "AGENTS.md")
    await mkdir(cwd, { recursive: true })
    await writeFile(filepath, "restart rules")
    const history = [message("restart", "a1", [tool("bash", [filepath], wrapper([[filepath, "restart rules"]]))])]

    const restartedProcess = await hooks(root, history)
    expect((await bash(restartedProcess, "restart", cwd)).output).toBe("command output")

    const droppedDir = path.join(root, "dropped")
    const retainedDir = path.join(root, "retained")
    const dropped = path.join(droppedDir, "AGENTS.md")
    const retained = path.join(retainedDir, "AGENTS.md")
    await mkdir(droppedDir)
    await mkdir(retainedDir)
    await writeFile(dropped, "dropped rules")
    await writeFile(retained, "retained rules")
    // Session.messages without a limit returns oldest-first history.
    const compactedHistory = [
      message("native-compaction", "old-assistant", [tool("read", [dropped], wrapper([[dropped, "dropped rules"]]))]),
      message("native-compaction", "tail-user", [], { role: "user" }),
      message("native-compaction", "tail-assistant", [tool("read", [retained], wrapper([[retained, "retained rules"]]))]),
      message("native-compaction", "compact", [{ type: "compaction", tail_start_id: "tail-user" }], { role: "user" }),
      message("native-compaction", "summary", [], {
        summary: true,
        finish: "stop",
        parentID: "compact",
      }),
      message("native-compaction", "continue", [], { role: "user" }),
    ]
    const compactedRestart = await hooks(root, compactedHistory)
    expect((await bash(compactedRestart, "native-compaction", retainedDir)).output).toBe("command output")
    expect((await bash(compactedRestart, "native-compaction", droppedDir)).output)
      .toContain(`Instructions from: ${dropped}`)
  })

  test("reattaches when media or compacted output retains metadata without a visible reminder", async () => {
    const root = path.join(sandbox, "media")
    const cwd = path.join(root, "repo")
    const filepath = path.join(cwd, "AGENTS.md")
    await mkdir(cwd, { recursive: true })
    await writeFile(filepath, "media rules")
    const plugin = await hooks(root)
    await prime(plugin, "media")

    const mediaRead = output("Image read successfully")
    mediaRead.metadata.loaded = [filepath]
    await plugin["tool.execute.after"](
      { tool: "read", sessionID: "media", callID: "read", args: { filePath: "image.png" } },
      mediaRead,
    )
    expect((await bash(plugin, "media", cwd)).output).toContain(`Instructions from: ${filepath}`)

    const mediaHistory = [message("media-restart", "a1", [tool("read", [filepath], "Image read successfully")])]
    const mediaTransform = await hooks(root)
    await prime(mediaTransform, "media-transform", [
      message("media-transform", "a1", [tool("read", [filepath], "Image read successfully")]),
    ])
    expect((await bash(mediaTransform, "media-transform", cwd)).output).toContain(`Instructions from: ${filepath}`)
    const mediaRestart = await hooks(root, mediaHistory)
    expect((await bash(mediaRestart, "media-restart", cwd)).output).toContain(`Instructions from: ${filepath}`)

    const omittedPart = tool(
      "bash",
      [filepath],
      "Output omitted due to a compaction operation. [content-id]",
    )
    const omittedHistory = [message("omitted", "a1", [omittedPart])]
    const omittedTransform = await hooks(root)
    await prime(omittedTransform, "omitted-transform", [message("omitted-transform", "a1", [omittedPart])])
    expect((await bash(omittedTransform, "omitted-transform", cwd)).output).toContain(`Instructions from: ${filepath}`)
    const omittedRestart = await hooks(root, omittedHistory)
    expect((await bash(omittedRestart, "omitted", cwd)).output).toContain(`Instructions from: ${filepath}`)
  })

  test("skips empty instructions and paths already present in the system prompt", async () => {
    const root = path.join(sandbox, "system")
    const emptyDir = path.join(root, "empty")
    const configuredDir = path.join(root, "configured")
    const configured = path.join(configuredDir, "AGENTS.md")
    await mkdir(emptyDir, { recursive: true })
    await mkdir(configuredDir)
    await writeFile(path.join(emptyDir, "AGENTS.md"), "")
    await writeFile(configured, "configured rules")

    const plugin = await hooks(root)
    await prime(plugin, "systemic")
    await prime(plugin, "other")
    expect((await bash(plugin, "systemic", emptyDir)).output).toBe("command output")

    await plugin["experimental.chat.system.transform"](
      { sessionID: "systemic", model: {} },
      { system: [`base system\nInstructions from: ${configured}\nconfigured rules`] },
    )
    await plugin["experimental.chat.system.transform"](
      { sessionID: "systemic", model: {} },
      { system: [] },
    )
    expect((await bash(plugin, "systemic", configuredDir)).output).toBe("command output")
    expect((await bash(plugin, "other", configuredDir)).output).toContain(`Instructions from: ${configured}`)

    await plugin.event({
      event: { type: "session.deleted", properties: { sessionID: "systemic", info: {} } },
    })
    expect((await bash(plugin, "systemic", configuredDir)).output).toContain(`Instructions from: ${configured}`)
  })

  test("rejects external real paths but preserves in-tree directory symlinks", async () => {
    const root = path.join(sandbox, "symlinks")
    const external = path.join(sandbox, "symlinks-external")
    const linkedCwd = path.join(root, "external-cwd")
    const linkedFileDir = path.join(root, "external-file")
    const internal = path.join(root, "internal")
    const internalLink = path.join(root, "internal-link")
    await mkdir(root)
    await mkdir(external)
    await mkdir(linkedFileDir)
    await mkdir(internal)
    const externalAgent = path.join(external, "AGENTS.md")
    await writeFile(externalAgent, "external rules")
    await chmod(externalAgent, 0o000)
    await writeFile(path.join(internal, "AGENTS.md"), "internal rules")
    await symlink(external, linkedCwd)
    await symlink(externalAgent, path.join(linkedFileDir, "AGENTS.md"))
    await symlink(internal, internalLink)

    const plugin = await hooks(root)
    await prime(plugin, "external-cwd")
    await prime(plugin, "external-file")
    await prime(plugin, "internal-link")
    expect((await bash(plugin, "external-cwd", linkedCwd)).output).toBe("command output")
    expect((await bash(plugin, "external-file", linkedFileDir)).output).toBe("command output")
    expect((await bash(plugin, "internal-link", internalLink)).output)
      .toContain(`Instructions from: ${path.join(internalLink, "AGENTS.md")}`)
  })

  test("keeps shell output visible when history or filesystem inspection fails", async () => {
    const apiRoot = path.join(sandbox, "api-error")
    const apiCwd = path.join(apiRoot, "repo")
    await mkdir(apiCwd, { recursive: true })
    await writeFile(path.join(apiCwd, "AGENTS.md"), "api rules")
    const apiPlugin = await hooks(apiRoot, [], new Error("history unavailable"))
    const apiResult = await bash(apiPlugin, "api-error", apiCwd)
    expect(apiResult.output).toStartWith("command output")
    expect(apiResult.output).toContain("history unavailable")
    expect(apiResult.metadata).toMatchObject({ exit: 0, retained: true, shellAgents: { error: "history unavailable" } })

    const fsRoot = path.join(sandbox, "fs-error")
    const fsCwd = path.join(fsRoot, "repo")
    await mkdir(fsCwd, { recursive: true })
    await symlink("AGENTS.md", path.join(fsCwd, "AGENTS.md"))
    const fsPlugin = await hooks(fsRoot)
    await prime(fsPlugin, "fs-error")
    const fsResult = await bash(fsPlugin, "fs-error", fsCwd)
    expect(fsResult.output).toStartWith("command output")
    expect(fsResult.metadata.shellAgents.error).toContain("symbolic links")
  })
})
