---
description: Review this session and propose durable memory updates before approval
---
Review the work in this session and propose durable agent-memory updates. This is a consolidation pass for future sessions, not a status report.

If `agents-md-mastery` is available, use or load it before judging candidates. Otherwise follow visible instruction files and keep the review narrow.

Treat `$ARGUMENTS` as optional focus only when it was interpolated to a non-empty value. If interpolation is unavailable or the token remains literal, proceed without extra focus.

Do not edit files, commit, or change durable memory until the operator accepts a specific proposal. `nothing to write` is a valid result.

## Source

Use only evidence and targets visible in the current harness: the conversation, tool results, diffs, current workspace, and files you can actually inspect. Re-read every visible instruction or memory file you might propose changing, including:

- the project `AGENTS.md`, when present
- a global instruction file, when visible
- any scratchpad or self-improvement file or section that is visible or referenced by visible instructions
- the current Cursor User Rules text, only when it was supplied or visible in the conversation

Do not assume a path, section name, harness capability, or memory policy that is not visible. Do not invent repository facts. If a learning depends on a file or command, confirm it still exists.

Cursor User Rules is the manual target `cursor-user-rules:manual`. Require the current Rules text to be supplied or visible before conflict analysis. If it is unavailable, mark the conflict check as not performed rather than asking only for access; you may still propose paste-ready text. Never claim to read or edit Cursor Settings.

## Pause

Before proposing, state briefly:

1. The session goal in one sentence, then what actually happened.
2. Three to five decisions, not topics.
3. What remains open and why: missing information, operator decision, or out of scope.
4. Assumptions that would invalidate those decisions if wrong.
5. What occupied attention but can be dropped, such as false starts or superseded approaches.

Keep this recap short. It is for calibration, not durable memory.

## Filter

A candidate is worth proposing only if a fresh agent session would act differently with it present.

Reject:

- facts a competent agent can read from the code or commands
- generic advice
- one-off incident notes that will not recur
- rules tied to one ticket or narrow incident unless they generalize to a named class of work
- duplicates of existing instructions

Classify each keeper:

- **Scratchpad:** provisional cross-project operator preferences, including voice, interaction style, and personification, as well as workflow, routing rules, or recurring gotchas. Keep them in the user's existing scratchpad or self-improvement section while evidence is limited.
- **Project instructions:** repository-specific conventions, commands, paths, ownership boundaries, or gotchas that belong in the project's `AGENTS.md`.
- **Global instructions:** mature, cross-project behavior that belongs in the user's global `AGENTS.md`. Use a higher bar than the scratchpad and do not promote a provisional learning directly.
- **Cursor User Rules:** mature, cross-project behavior for `cursor-user-rules:manual`. Use this target only for Cursor and never claim direct Settings access.
- **Skill gap:** a missing reusable technique that cannot be expressed as one concise rule. Report it, but do not author a skill during reflection.

The promotion path is scratchpad first, then global instructions or Cursor User Rules only after repeated cross-project evidence and explicit operator approval. A preference about voice, interaction style, or personification follows the same path as an operational rule.

## Propose and wait

For every keeper, use this shape:

### N. [short name]

- **Where:** `scratchpad:<path>#<section>`, `project:<path>#<section>`, `global:<path>#<section>`, or `cursor-user-rules:manual`. If a scratchpad or global file is inaccessible, use `scratchpad:manual` or `global:manual` without inventing a path.
- **What:** the exact rule or sentence to write
- **Why:** the repeatable mistake it prevents, with evidence from this session
- **How:** add, replace, move, or delete, naming the exact target
- **Conflict check:** overlapping or contradictory instructions, or `none`

List rejected candidates in one short **Not encoded** section so the filter is visible. If there are no keepers, say so and stop.

Then wait for the operator. Accept, reject, or rewrite each item independently. Apply only accepted edits and only to the agreed file and section.

For an accepted inaccessible scratchpad or global target, return the exact approved text, identify the manual destination, give manual paste instructions, and state that it was not applied. For an accepted `cursor-user-rules:manual` item, return the exact approved text followed by: "Open Cursor Customize -> Rules -> User Rules, reconcile this text with the supplied current Rules, and paste the resulting Rules text manually." State that it was not applied, and never claim to read or edit Cursor Settings.

After applying accepted items, show diffs for edited files and summarize what was applied, returned for manual paste, rejected, or left unchanged. Do not broaden the accepted edits into a general instructions rewrite.
