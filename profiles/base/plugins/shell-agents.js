// Extends OpenCode's nested AGENTS.md discovery to shell output while deduplicating
// only reminders still visible in active history. OpenCode 1 loads `server` (Bash and
// Read output); OpenCode 2 loads `setup` (shell output only). Verify with tests/shell-agents.test.js.
import { readFile, realpath, stat } from "node:fs/promises"
import os from "node:os"
import path from "node:path"

const INSTRUCTION_FILE = "AGENTS.md"
const PLUGIN_METADATA = "shellAgents"
const INSTRUCTION_PREFIX = "Instructions from: "
// OpenCode 2 frame: a header line naming the canonical path and the rendered body length
// in UTF-16 code units, the file content with BODY_PREFIX before every line, then a close
// line. Headers count only at a line start, which no body line can be, so text quoted in a
// body stays inert even when the host truncates the frame and joins later messages to it.
const FRAME_OPEN = '<shell-agents version="1" path='
const FRAME_LENGTH = / length="(\d{1,15})">\n/y
const FRAME_CLOSE = "\n</shell-agents>"
const BODY_PREFIX = "> "
const LINE_BREAK = /\r\n|\r|\n/

function isInside(root, target) {
  const relative = path.relative(root, target)
  return relative !== "" && relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative)
}

async function pathIdentity(filepath) {
  try {
    return await realpath(filepath)
  } catch {
    return path.resolve(filepath)
  }
}

function carriesReminder(part, filepath) {
  return typeof part.state.output === "string"
    && part.state.output.includes(`${INSTRUCTION_PREFIX}${filepath}\n`)
}

async function loadedPaths(messages) {
  const result = new Set()
  for (const message of messages) {
    for (const part of message.parts ?? []) {
      if (part.type !== "tool" || part.state?.status !== "completed" || part.state.time?.compacted) continue

      let loaded
      if (part.tool === "read") loaded = part.state.metadata?.loaded
      if (part.tool === "bash") loaded = part.state.metadata?.[PLUGIN_METADATA]?.loaded
      if (!Array.isArray(loaded)) continue
      for (const filepath of loaded) {
        if (typeof filepath === "string" && carriesReminder(part, filepath)) {
          result.add(await pathIdentity(filepath))
        }
      }
    }
  }
  return result
}

// Match OpenCode's active native-compaction view. Callers provide newest-first messages.
function filterCompacted(messages) {
  const result = []
  const completed = new Set()
  let retain
  for (const message of messages) {
    result.push(message)
    if (retain) {
      if (message.info.id === retain) break
      continue
    }
    if (message.info.role === "user" && completed.has(message.info.id)) {
      const part = message.parts.find((item) => item.type === "compaction")
      if (!part) continue
      if (!part.tail_start_id) break
      retain = part.tail_start_id
      if (message.info.id === retain) break
      continue
    }
    if (message.info.role === "assistant" && message.info.summary && message.info.finish && !message.info.error) {
      completed.add(message.info.parentID)
    }
  }
  return result
}

function reminder(entries) {
  return `\n\n<system-reminder>\n${entries
    .map((entry) => `Instructions from: ${entry.filepath}\n${entry.content}`)
    .join("\n\n")}\n</system-reminder>`
}

async function instructionAt(directory) {
  const filepath = path.join(directory, INSTRUCTION_FILE)
  try {
    if ((await stat(filepath)).isFile()) return filepath
  } catch (error) {
    if (error?.code !== "ENOENT" && error?.code !== "ENOTDIR") throw error
  }
}

async function instructionsFor(root, rootReal, cwd) {
  // Native Read does not walk outside the OpenCode directory either.
  if (!isInside(root, cwd)) return []
  let cwdReal
  try {
    cwdReal = await realpath(cwd)
  } catch (error) {
    if (error?.code === "ENOENT" || error?.code === "ENOTDIR") return []
    throw error
  }
  if (!isInside(rootReal, cwdReal)) return []

  const files = []
  const seen = new Set()
  let current = cwd
  while (isInside(root, current)) {
    const filepath = await instructionAt(current)
    if (filepath) {
      try {
        const identity = await realpath(filepath)
        if (isInside(rootReal, identity) && !seen.has(identity)) {
          const content = await readFile(filepath, "utf8")
          if (content !== "") {
            seen.add(identity)
            files.push({ filepath, identity, content })
          }
        }
      } catch (error) {
        if (error?.code !== "ENOENT" && error?.code !== "ENOTDIR") throw error
      }
    }
    current = path.dirname(current)
  }
  return files
}

function responseData(response) {
  if (Array.isArray(response)) return response
  if (response?.error) throw new Error(String(response.error.message ?? response.error))
  if (Array.isArray(response?.data)) return response.data
  throw new Error("OpenCode returned an invalid session history response")
}

function errorMessage(error) {
  return error instanceof Error ? error.message : String(error)
}

function diagnosticReminder(message) {
  return `<system-reminder>\nshell-agents could not load directory instructions: ${message}\n</system-reminder>`
}

function diagnostic(output, error) {
  const message = errorMessage(error)
  output.output += `\n\n${diagnosticReminder(message)}`
  output.metadata = {
    ...(output.metadata && typeof output.metadata === "object" ? output.metadata : {}),
    [PLUGIN_METADATA]: {
      ...(output.metadata?.[PLUGIN_METADATA] ?? {}),
      error: message,
    },
  }
}

async function ShellAgentsServer({ client, directory }) {
  const root = path.resolve(directory)
  const rootReal = await realpath(root)
  const sessions = new Map()
  const loading = new Map()
  const systemPaths = new Map()

  async function claims(sessionID) {
    const cached = sessions.get(sessionID)
    if (cached) return cached

    let pending = loading.get(sessionID)
    if (!pending) {
      pending = (async () => {
        const response = await client.session.messages({
          path: { id: sessionID },
          query: { directory: root },
        })
        // Session.messages without a limit returns chronological history.
        const loaded = await loadedPaths(filterCompacted([...responseData(response)].reverse()))
        const current = sessions.get(sessionID)
        if (current) return current
        if (loading.get(sessionID) === pending) sessions.set(sessionID, loaded)
        return loaded
      })()
      loading.set(sessionID, pending)
    }

    try {
      return await pending
    } finally {
      if (loading.get(sessionID) === pending) loading.delete(sessionID)
    }
  }

  async function handleRead(input, output) {
    const paths = output.metadata?.loaded
    if (!Array.isArray(paths) || paths.length === 0) return

    const entries = []
    for (const value of paths) {
      if (typeof value !== "string") return
      const filepath = path.resolve(value)
      try {
        entries.push({ filepath, identity: await pathIdentity(filepath), content: await readFile(filepath, "utf8") })
      } catch (error) {
        if (error?.code === "ENOENT" || error?.code === "ENOTDIR") return
        throw error
      }
    }

    const suffix = reminder(entries)
    if (!output.output.endsWith(suffix)) return // Images and PDFs expose loaded metadata without a reminder.

    const active = await claims(input.sessionID)
    const systemic = systemPaths.get(input.sessionID)
    const globalSystemic = systemPaths.get("")
    const kept = []
    for (const entry of entries) {
      if (active.has(entry.identity) || systemic?.has(entry.identity) || globalSystemic?.has(entry.identity)) continue
      active.add(entry.identity)
      kept.push(entry)
    }

    output.output = output.output.slice(0, -suffix.length) + (kept.length > 0 ? reminder(kept) : "")
    output.metadata = { ...output.metadata, loaded: kept.map((entry) => entry.filepath) }
  }

  async function handleBash(input, output) {
    const workdir = input.args?.workdir
    const cwd = path.resolve(root, typeof workdir === "string" ? workdir : ".")
    const entries = await instructionsFor(root, rootReal, cwd)
    if (entries.length === 0) return

    const active = await claims(input.sessionID)
    const systemic = systemPaths.get(input.sessionID)
    const globalSystemic = systemPaths.get("")
    const attached = []
    for (const entry of entries) {
      if (active.has(entry.identity) || systemic?.has(entry.identity) || globalSystemic?.has(entry.identity)) continue
      active.add(entry.identity)
      attached.push(entry)
    }
    if (attached.length === 0) return

    output.output += reminder(attached)
    output.metadata = {
      ...(output.metadata && typeof output.metadata === "object" ? output.metadata : {}),
      [PLUGIN_METADATA]: {
        ...(output.metadata?.[PLUGIN_METADATA] ?? {}),
        loaded: attached.map((entry) => entry.filepath),
      },
    }
  }

  return {
    "experimental.chat.messages.transform": async (_input, output) => {
      const bySession = new Map()
      for (const message of output.messages) {
        const sessionID = message.info?.sessionID
        if (typeof sessionID !== "string") continue
        const list = bySession.get(sessionID) ?? []
        list.push(message)
        bySession.set(sessionID, list)
      }
      for (const [sessionID, messages] of bySession) {
        sessions.set(sessionID, await loadedPaths(messages))
      }
    },
    "experimental.chat.system.transform": async (input, output) => {
      const loaded = new Set()
      for (const text of output.system) {
        for (const line of text.split("\n")) {
          if (!line.startsWith(INSTRUCTION_PREFIX)) continue
          const filepath = line.slice(INSTRUCTION_PREFIX.length)
          if (path.isAbsolute(filepath)) loaded.add(await pathIdentity(filepath))
        }
      }
      const key = input.sessionID ?? ""
      if (loaded.size > 0 || !systemPaths.has(key)) systemPaths.set(key, loaded)
    },
    event: async ({ event }) => {
      if (event.type !== "session.deleted") return
      const sessionID = event.properties.sessionID
      sessions.delete(sessionID)
      loading.delete(sessionID)
      systemPaths.delete(sessionID)
    },
    "tool.execute.after": async (input, output) => {
      try {
        const tool = input.tool.toLowerCase()
        if (tool === "read") await handleRead(input, output)
        if (tool === "bash") await handleBash(input, output)
      } catch (error) {
        diagnostic(output, error)
      }
    },
  }
}

function frame(entry) {
  // Prefixing after each original line break keeps the content recoverable exactly.
  const body = BODY_PREFIX + entry.content.replace(new RegExp(LINE_BREAK, "g"), (lineBreak) => lineBreak + BODY_PREFIX)
  return `<system-reminder>\n${INSTRUCTION_PREFIX}${entry.filepath}\n${FRAME_OPEN}${JSON.stringify(entry.identity)} length="${body.length}">\n${body}${FRAME_CLOSE}\n</system-reminder>`
}

// Returns the claimed path when a complete frame starts at `start`.
function framedPath(text, start) {
  const quote = start + FRAME_OPEN.length
  if (text[quote] !== '"') return
  let end = quote + 1
  while (end < text.length && text[end] !== '"') {
    if (text[end] === "\n") return
    end += text[end] === "\\" ? 2 : 1
  }
  if (end >= text.length) return
  let filepath
  try {
    filepath = JSON.parse(text.slice(quote, end + 1))
  } catch {
    return
  }
  if (typeof filepath !== "string" || !path.isAbsolute(filepath)) return

  FRAME_LENGTH.lastIndex = end + 1
  const match = FRAME_LENGTH.exec(text)
  if (!match) return
  const bodyStart = FRAME_LENGTH.lastIndex
  const bodyEnd = bodyStart + Number(match[1])
  if (!text.startsWith(FRAME_CLOSE, bodyEnd)) return
  // A truncated frame followed by other text leaves an unprefixed line inside the length.
  if (!text.slice(bodyStart, bodyEnd).split(LINE_BREAK).every((line) => line.startsWith(BODY_PREFIX))) return
  return filepath
}

function addFramedPaths(claims, text) {
  if (typeof text !== "string") return
  // Each header is read on its own; no body can hide or contain a line-start header.
  const lines = `\n${text}`
  const header = `\n${FRAME_OPEN}`
  for (let at = lines.indexOf(header); at !== -1; at = lines.indexOf(header, at + 1)) {
    const filepath = framedPath(lines, at + 1)
    if (filepath) claims.add(filepath)
  }
}

// Model messages from the `context` hook. Only text the model receives counts.
function contextClaims(messages) {
  const claims = new Set()
  for (const message of messages) {
    const content = typeof message?.content === "string" ? [{ type: "text", text: message.content }] : message?.content
    if (!Array.isArray(content)) continue
    for (const part of content) {
      if (part?.type === "text") addFramedPaths(claims, part.text)
      if (part?.type !== "tool-result") continue
      if (part.result?.type === "text") addFramedPaths(claims, part.result.value)
      if (part.result?.type === "content" && Array.isArray(part.result.value)) {
        for (const item of part.result.value) if (item?.type === "text") addFramedPaths(claims, item.text)
      }
    }
  }
  return claims
}

// Public messages from `session.context`, used before this process has seen a `context`
// hook for the session. Provider-native checkpoints are opaque, so they claim nothing.
function historyClaims(messages) {
  const claims = new Set()
  for (const message of messages) {
    switch (message?.type) {
      case "user":
        addFramedPaths(claims, message.text)
        for (const skill of message.skills ?? []) addFramedPaths(claims, skill?.text)
        break
      case "synthetic":
      case "skill":
      case "system":
        addFramedPaths(claims, message.text)
        break
      case "shell":
        if (message.metadata?.background !== true) addFramedPaths(claims, message.output?.output)
        break
      case "assistant":
        for (const part of message.content ?? []) {
          if (part?.type === "text") addFramedPaths(claims, part.text)
          if (part?.type === "tool" && part.state?.status === "completed") {
            for (const item of part.state.content ?? []) if (item?.type === "text") addFramedPaths(claims, item.text)
          }
        }
        break
      case "compaction":
        if (message.status === "completed" && message.providerContext === undefined) {
          addFramedPaths(claims, message.summary)
          addFramedPaths(claims, message.recent)
        }
        break
    }
  }
  return claims
}

// Mirrors OpenCode 2's shell working-directory resolution, including `~` expansion.
function shellDirectory(root, workdir) {
  if (typeof workdir !== "string") return root
  const home = os.homedir()
  const expanded = workdir === "~" ? home : workdir.startsWith("~/") ? path.join(home, workdir.slice(2)) : workdir
  return path.resolve(root, expanded)
}

function appendText(result, text) {
  const content = typeof result.content === "string" ? [{ type: "text", text: result.content }] : result.content
  if (!Array.isArray(content)) return false
  result.content = [...content, { type: "text", text }]
  return true
}

async function setupV2(ctx) {
  // sessionID -> { claims: Set of canonical paths | undefined, seeding: Promise | undefined }
  const sessions = new Map()

  function recordFor(sessionID) {
    let record = sessions.get(sessionID)
    if (!record) {
      record = { claims: undefined, seeding: undefined }
      sessions.set(sessionID, record)
    }
    return record
  }

  function seed(sessionID, record) {
    if (record.claims) return
    if (!record.seeding) {
      const seeding = (async () => historyClaims(await ctx.session.context({ sessionID })))()
        .then((claims) => {
          // A `context` hook that ran meanwhile replaced the record from newer history.
          if (sessions.get(sessionID) === record && record.claims === undefined) record.claims = claims
        })
        .finally(() => {
          if (record.seeding === seeding) record.seeding = undefined
        })
      record.seeding = seeding
    }
    return record.seeding
  }

  async function handleShell(event) {
    // Bind to the current record before any await. A `context` hook that runs meanwhile
    // starts a newer step with a new record, and this shell's result belongs to the old one.
    const record = recordFor(event.sessionID)
    const session = await ctx.session.get({ sessionID: event.sessionID })
    const root = path.resolve(session.location.directory)
    const cwd = shellDirectory(root, event.input?.workdir)
    const entries = await instructionsFor(root, await realpath(root), cwd)
    if (entries.length === 0) return

    await seed(event.sessionID, record)
    if (sessions.get(event.sessionID) !== record || !record.claims) return

    // No awaits from here on, so concurrent shells cannot both deliver one file.
    const fresh = entries.filter((entry) => !record.claims.has(entry.identity))
    if (fresh.length === 0) return
    for (const entry of fresh) {
      if (!appendText(event.result, frame(entry))) throw new Error("OpenCode returned a shell result without model-facing content")
    }
    for (const entry of fresh) record.claims.add(entry.identity)
  }

  await ctx.session.hook("context", (event) => {
    sessions.set(event.sessionID, { claims: contextClaims(event.messages), seeding: undefined })
  })

  await ctx.tool.hook("execute.after", async (event) => {
    if (event.tool !== "shell" || event.status !== "completed") return
    try {
      await handleShell(event)
    } catch (error) {
      const message = errorMessage(error)
      appendText(event.result, diagnosticReminder(message))
      event.result.metadata = {
        ...(event.result.metadata && typeof event.result.metadata === "object" ? event.result.metadata : {}),
        [PLUGIN_METADATA]: { error: message },
      }
    }
  })

  const subscription = new AbortController()
  void (async () => {
    for await (const event of ctx.event.subscribe({ signal: subscription.signal })) {
      if (event?.type === "session.deleted") sessions.delete(event.data?.sessionID)
    }
  })().catch(() => {}) // A lost subscription only stops pruning records of deleted sessions.

  return () => {
    subscription.abort()
    sessions.clear()
  }
}

export default { id: "shell-agents", server: ShellAgentsServer, setup: setupV2 }
