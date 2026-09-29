// Extends OpenCode's nested AGENTS.md discovery to Bash output while deduplicating
// only reminders still visible in active history. Verify with the adjacent Bun tests.
import { readFile, realpath, stat } from "node:fs/promises"
import path from "node:path"

const INSTRUCTION_FILE = "AGENTS.md"
const PLUGIN_METADATA = "shellAgents"
const INSTRUCTION_PREFIX = "Instructions from: "

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

function diagnostic(output, error) {
  const message = error instanceof Error ? error.message : String(error)
  output.output += `\n\n<system-reminder>\nshell-agents could not load directory instructions: ${message}\n</system-reminder>`
  output.metadata = {
    ...(output.metadata && typeof output.metadata === "object" ? output.metadata : {}),
    [PLUGIN_METADATA]: {
      ...(output.metadata?.[PLUGIN_METADATA] ?? {}),
      error: message,
    },
  }
}

export default async function ShellAgentsPlugin({ client, directory }) {
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
