---
description: Review the current Cursor session and propose durable agent-memory learnings without writing before approval
---
Review the current session and propose durable updates to the operator's agent instructions. This is a consolidation pass for future sessions, not a status report.

Use any focus supplied with the command. Do not edit files, Rules, settings, or other durable state until the operator accepts a specific proposal. `nothing to write` is a valid result.

## Available evidence

Use only the visible conversation, current workspace, available diffs, and files you can inspect from this Cursor session. Re-read each target before proposing a change.

Check the project `AGENTS.md` when present. Check a scratchpad or global instruction file only when it is available to the current workspace or the operator identifies it. If a global target is unavailable, propose exact text for it but do not claim to have read or edited it.

Cursor Settings -> User Rules is a manual, non-file target. Analyze it only when the current Rules text is supplied or visible in the conversation. Never claim to read or edit Cursor Settings.

Do not assume a path, section name, or memory policy that is not visible. Do not invent repository facts. Confirm any file, command, or convention used as evidence.

## Pause

Before proposing, state briefly:

1. The session goal in one sentence, then what actually happened.
2. Three to five decisions, not topics.
3. What remains open and why: missing information, operator decision, or out of scope.
4. Assumptions that would invalidate those decisions if wrong.
5. False starts or superseded approaches that can be dropped.

## Filter

Keep a candidate only when it would change how a fresh agent session acts.

Reject facts already readable from the repository, generic advice, one-off incident notes, ticket-specific rules that do not generalize, and duplicates of existing instructions.

Classify each keeper as one of:

- **Scratchpad:** provisional cross-project operator preferences, including voice, interaction style, and personification, as well as workflows or recurring gotchas. Keep them in an existing scratchpad or self-improvement section while evidence is limited.
- **Project instructions:** a repository-specific convention, command, path, ownership boundary, or gotcha for the project's `AGENTS.md`.
- **Global instructions:** a mature cross-project behavior for the operator's global agent instructions. Do not promote a provisional learning directly.
- **Cursor User Rules:** a mature cross-project behavior for the manual Cursor User Rules target. Use this only when the current Rules text was supplied or visible and can be checked for conflicts.
- **Skill gap:** a reusable technique too substantial for one concise rule. Report it, but do not create it during reflection.

The promotion path is scratchpad first, then global instructions or Cursor User Rules only after repeated cross-project evidence and explicit operator approval. A preference about voice, interaction style, or personification follows the same path as an operational rule.

## Propose and wait

For every keeper, provide:

### N. [short name]

- **Where:** `scratchpad:<path>#<section>`, `project:<path>#<section>`, `global:<path>#<section>`, or `cursor-user-rules:manual`
- **What:** the exact rule or sentence to write
- **Why:** the repeatable mistake it prevents, with session evidence
- **How:** add, replace, move, or delete, naming the exact target
- **Conflict check:** overlapping or contradictory instructions, or `none`

Add a short **Not encoded** section listing rejected candidates. If there are no keepers, say so and stop.

Wait for the operator to accept, reject, or rewrite each item. Apply only accepted edits to accessible files and only in the agreed sections. For an inaccessible file target, return the approved exact change and state that it was not applied. For `cursor-user-rules:manual`, return the approved exact text followed by this manual paste instruction: "Open Cursor Settings -> Rules, reconcile the approved text with the supplied current Rules, and paste the resulting Rules text manually."

After writing, show the resulting diff and stop. Do not turn the accepted edits into a broader instructions rewrite.
