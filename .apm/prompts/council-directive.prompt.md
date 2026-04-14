---
description: Turn a rough request into a reusable council directive
---
Prepare a council directive that can be reused in the current session or pasted into a new chat.

Use this operator-provided topic, prompt, or context if provided: $ARGUMENTS

Do not run the council unless the operator explicitly asks you to do that after the directive is prepared.
Do not write code.
Do not invent repository facts, file paths, or technical validation that have not already been established in this session.

Your job is to turn a rough request into the smallest directive that lets `/council` run cleanly.

Ask exactly one question at a time when important information is missing.
Prefer the `question` tool when it helps the operator answer quickly.
Usually 1-3 questions is enough. Do not ask more than 4 unless the operator explicitly wants a deeper setup.

Prioritize clarifying:

- the objective the council must answer
- the direction or lens the council should take
- which councillors or alias to include
- constraints, boundaries, or non-goals
- what output the operator wants back
- whether the council should run in the current session or a new session

Council aliases:

- `design` -> `scout-researcher`, `architect-planner`, `hygienic-reviewer`, `forager-smart`
- `decision` -> `scout-researcher`, `architect-planner`, `hygienic-reviewer-ultrabrain`, `forager-smart`
- `minimal-change` -> `scout-researcher`, `simplicity-reviewer`, `hygienic-reviewer`, `forager-simple`
- `documents` -> `scout-researcher`, `forager-documents`, `hygienic-reviewer-documents`

If the operator requests a `worker` seat without naming one, default to:

- `forager-simple` for clearly minimal-change work
- otherwise `forager-smart`

If the best council is still unclear, recommend one alias and explain why.

Default session-mode guidance:

- recommend `current` for quick same-session analysis with enough context already established
- recommend `new` when the council needs a clean handoff, a reusable brief, or a larger context reset

At the end, output all of the following:

## Council Directive

- objective:
- direction:
- include:
- constraints:
- context:
- assumptions needing validation:
- desired output:
- session mode:

## Recommendation

State whether the operator should run `/council` in the current session or start a new chat, and explain why.

## Recommended Invocation

If `session mode` is `current`, provide a compact `/council` invocation using the directive.

If `session mode` is `new`, provide a compact `/council` invocation and a paste-ready prompt block for a new chat.

## Paste Into New Chat

When `session mode` is `new`, output a copy-paste-ready block that includes the council directive and asks the next session to run a read-only council with the requested direction.

When `session mode` is `current`, say that a new-chat prompt is not needed.
