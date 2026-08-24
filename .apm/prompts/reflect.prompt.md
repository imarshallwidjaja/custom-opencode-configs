---
description: Review this session and propose durable agent-memory learnings without writing before approval
---
Review the work in this session and propose durable agent-memory updates. This is a consolidation pass for future sessions, not a status report.

If `agents-md-mastery` is available, load it before judging candidates. Otherwise follow the current AGENTS.md instructions and keep the review narrow.

Use this extra focus if provided: $ARGUMENTS

Do not edit files, commit, or change durable memory until the operator accepts a specific proposal. `nothing to write` is a valid result.

## Source

Use the visible conversation, tool results, diffs, and current workspace. Re-read every instruction or memory file you might propose changing, including:

- the project `AGENTS.md`, when present
- the user's global `AGENTS.md`, typically `~/.config/opencode/AGENTS.md`, when available
- any scratchpad or self-improvement file or section referenced by those instructions

Do not assume a path, section name, or memory policy that is not present. Do not invent repository facts. If a learning depends on a file or command, confirm it still exists.

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
- **Skill gap:** a missing reusable technique that cannot be expressed as one concise rule. Report it, but do not author a skill during reflection.

The promotion path is scratchpad first, then global instructions only after repeated cross-project evidence and explicit operator approval. A preference about voice, interaction style, or personification follows the same path as an operational rule.

## Propose and wait

For every keeper, use this shape:

### N. [short name]

- **Where:** `scratchpad:<path>#<section>`, `project:<path>#<section>`, or `global:<path>#<section>`
- **What:** the exact rule or sentence to write
- **Why:** the repeatable mistake it prevents, with evidence from this session
- **How:** add, replace, move, or delete, naming the exact target
- **Conflict check:** overlapping or contradictory instructions, or `none`

List rejected candidates in one short **Not encoded** section so the filter is visible. If there are no keepers, say so and stop.

Then wait for the operator. Accept, reject, or rewrite each item independently. Apply only accepted edits and only to the agreed file and section.

After writing, show the diff and stop. Do not broaden the accepted edits into a general instructions rewrite.
