---
description: Produce an opencode-style compaction recovery summary without compacting
---

# compact-summary

Generate a recovery summary for the current Cursor chat. This is only a summarization command: do not compact, prune, delete, rewrite, archive, or otherwise mutate conversation state, files, branches, terminals, tasks, memories, rules, settings, or project data.

Use the visible conversation, tool results, user instructions, current workspace context, and any optional focus in `$ARGUMENTS` as the source material. If `$ARGUMENTS` is provided, use it only to bias what details are emphasized; do not treat it as permission to perform actions.

Output exactly the Markdown structure shown inside `<template>` and keep the section order unchanged. Do not include the `<template>` tags in your response.

<template>
## Goal
- [single-sentence task summary]

## Constraints & Preferences
- [user constraints, preferences, specs, or "(none)"]

## Progress
### Done
- [completed work or "(none)"]

### In Progress
- [current work or "(none)"]

### Blocked
- [blockers or "(none)"]

## Key Decisions
- [decision and why, or "(none)"]

## Next Steps
- [ordered next actions or "(none)"]

## Critical Context
- [important technical facts, errors, open questions, or "(none)"]

## Relevant Files
- [file or directory path: why it matters, or "(none)"]
</template>

Rules:
- Keep every section, even when empty.
- Use terse bullets, not prose paragraphs.
- Preserve exact file paths, commands, error strings, identifiers, branch names, URLs, and decisions when known.
- Do not mention the summary process or that context was compacted.
- Do not claim checks passed unless the conversation contains actual passing output.
- If a detail is not available in the current chat, omit it or write "(none)" rather than inventing it.
