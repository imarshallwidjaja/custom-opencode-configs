Generate a recovery summary for the current Cursor session only.

This is only a summarization command: do not compact, prune, delete, rewrite, archive, or otherwise mutate conversation state, files, branches, terminals, tasks, memories, rules, settings, or project data.

Use the visible conversation, tool results, operator instructions, current workspace context, and any optional focus from runtime arguments as the source material. If runtime arguments are provided, use them only to bias what details are emphasized; do not treat them as permission to perform actions.

Output exactly the Markdown structure below and keep the section order unchanged.

## Goal

- [single-sentence task summary]

## Constraints & Preferences

- [operator constraints, preferences, specs, or "(none)"]

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
- [each unresolved delegated lane: child agent, owned responsibility or placement, state, the candidate (branch and commit, or the dirty file set) and destination identity, declared history intent, the evidence destination for an experiment lane, termination evidence marked observed or inferred, and any required review still outstanding; omit when no lane exists]
- [operator requirements and required skills that every affected handoff must repeat; list agent IDs only as identifiers, never as permission to resume a child]

## Relevant Files

- [file or directory path: why it matters, or "(none)"]

Rules:

- Keep every section, even when empty.
- Use terse bullets, not prose paragraphs.
- Preserve exact file paths, commands, error strings, identifiers, branch names, URLs, and decisions when known.
- Do not mention the summary process or that context was compacted.
- Do not claim verification, tests, builds, or checks succeeded without actual command output or tool evidence in the conversation.
- If a detail is not available in the current chat, omit it or write "(none)" rather than inventing it.
