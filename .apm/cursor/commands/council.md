Run a read-only council session using the available Cursor subagents or the requested configured council group, then return one synthesized answer. If no usable councillors can be identified from available Cursor subagents or the requested group, stop and report what was missing instead of running council.

Use the operator-provided question, directive, or context from runtime arguments.

Treat the council as an analysis workflow, not an execution workflow.

Never modify files.
Never apply patches.
Never create commits, branches, pull requests, plans, or worktrees as part of the council.
Use only read and research tools when tool use is needed.

If the operator already supplied a structured council directive, use it. If the input is loose or incomplete, normalize it into a council directive first. Ask at most 2 clarification questions before running the council. Prefer to infer a sensible default when the missing detail is low risk.

Normalize the request into these council directive fields:

- objective
- direction
- include
- constraints
- context
- assumptions needing validation
- desired output

Use only councillors identified for this run from configured Cursor subagents or groups. Do not substitute stale aliases, excluded agents, unrequested or invented agents, or duplicates back into the run.

Run the council by invoking each identified councillor in a fresh Cursor subagent session. Use Cursor subagents in parallel when the environment supports it and the councillors are independent. Otherwise, run them serially or ask the operator to run the named councillors. If a councillor session fails, retry it in a new fresh session rather than resuming the failed one.

Give every councillor the same core problem statement plus a role-specific framing. Include this read-only contract in every councillor prompt:

```text
This is a read-only council session.

You may inspect repository context and use read, search, and research tools if available.
Do not modify files.
Do not apply patches.
Do not create commits, branches, pull requests, plans, or worktrees.
Do not claim to have changed anything.

Return analysis, risks, tradeoffs, and recommendations only.
```

Ask each councillor to return:

- one-paragraph verdict
- key reasoning
- risks or objections
- assumptions and unknowns
- recommended next step

If `include` names too many councillors, trim to the smallest useful set for synthesis, usually 3-4 seats, without violating the operator's requested member list.

After all councillors respond, synthesize the result yourself.

Synthesis rules:

- ground claims in current session evidence when available
- distinguish established facts from assumptions needing validation
- do not average vague opinions into a bland compromise
- preserve the strongest disagreements when they are decision-relevant
- give a clear recommendation even when the council is split

When usable councillors are identified and council runs, use this output format:

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
