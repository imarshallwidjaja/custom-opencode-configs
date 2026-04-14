---
description: Run a read-only council of subagents and synthesize one recommendation
---
Run a read-only council session and return one synthesized answer.

Use this operator-provided question, directive, or context if provided: $ARGUMENTS

Treat the council as an analysis workflow, not an execution workflow.

Never modify files.
Never apply patches.
Never create commits, branches, PRs, plans, or worktrees as part of the council.
Use only read and research tools when tool use is needed.

If the operator already supplied a structured council directive, use it.
If the input is loose or incomplete, normalize it into a council directive first.
Ask at most 2 clarification questions before running the council. Prefer to infer a sensible default when the missing detail is low risk.

Normalize the request into these council directive fields:

- objective
- direction
- include
- constraints
- context
- assumptions needing validation
- desired output

Council aliases:

- `design` -> `scout-researcher`, `architect-planner`, `hygienic-reviewer`, `forager-smart`
- `decision` -> `scout-researcher`, `architect-planner`, `hygienic-reviewer-ultrabrain`, `forager-smart`
- `minimal-change` -> `scout-researcher`, `simplicity-reviewer`, `hygienic-reviewer`, `forager-simple`
- `documents` -> `scout-researcher`, `forager-documents`, `hygienic-reviewer-documents`

Allowed councillors:

- `scout-researcher`
- `architect-planner`
- `hygienic-reviewer`
- `hygienic-reviewer-ultrabrain`
- `hygienic-reviewer-documents`
- `simplicity-reviewer`
- `forager-smart`
- `forager-simple`
- `forager-documents`
- `forager-capable`

Do not use these as councillors:

- `hive-master`
- `swarm-orchestrator`

If the operator names `worker` without specifying which one, map it to:

- `forager-simple` for clearly minimal-change requests
- otherwise `forager-smart`

If `include` is missing, choose the best council alias for the request.
If `include` names too many councillors, trim the council to the smallest useful set, usually 3-4 seats.
If the request is code-heavy and implementation feasibility is a major risk, you may replace the worker seat with `forager-capable`.

Run the council by delegating each councillor in a fresh subagent session. Launch the councillor tasks in parallel when they are independent. If a councillor task fails, retry it in a new fresh session rather than resuming the failed one.

Give every councillor the same core problem statement plus a role-specific framing. Include this read-only contract in every councillor prompt:

```text
This is a read-only council session.

You may inspect repository context and use read, search, and research tools if available.
Do not modify files.
Do not apply patches.
Do not create commits, branches, PRs, plans, or worktrees.
Do not claim to have changed anything.

Return analysis, risks, tradeoffs, and recommendations only.
```

Ask each councillor to return:

- one-paragraph verdict
- key reasoning
- risks or objections
- assumptions and unknowns
- recommended next step

After all councillors respond, synthesize the result yourself.

Synthesis rules:

- ground claims in current session evidence when available
- distinguish established facts from assumptions needing validation
- do not average vague opinions into a bland compromise
- preserve the strongest disagreements when they are decision-relevant
- give a clear recommendation even when the council is split

Output format:

## Council Directive

- objective
- direction
- include
- constraints
- context
- assumptions needing validation
- desired output

## Council Result

## Agreement

## Disagreement

## Risks

## Recommendation

## Suggested Next Step

## Council Members

List the councillors that participated and why they were chosen.
