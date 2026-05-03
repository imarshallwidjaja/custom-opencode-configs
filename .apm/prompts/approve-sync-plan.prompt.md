---
description: Approve and sync a Hive plan, then produce execution-ready guidance
---
Finalize the current Hive plan for execution and return an operator-ready brief.

Additional operator input:
$ARGUMENTS

Follow this workflow exactly:

1. Identify the active feature name.
2. Read the plan and verify it is ready for execution.
3. Approve the plan.
4. Sync tasks from the approved plan.
5. Read the final plan state again after approval and sync.

If approval or sync fails, stop and report the exact blocker, what you attempted, and the shortest recovery path.

Return these sections with these headings:

## Feature

- feature name
- plan approval status
- task sync status

## Plan Readback

Summarize the final plan in plain language, including:

- objective and intended outcome
- scope boundaries and non-goals
- key constraints, assumptions, and risks
- dependency highlights

## Task Breakdown

For every task, explain:

- what it delivers
- why it matters
- key dependencies or ordering constraints
- what done looks like

## Recommended Execution Order

Give the best task order with reasoning. Use parallelism only where dependencies allow it, and call out tasks that must remain sequential.

## Session Strategy (Min Sessions, No Context Overload)

Design the fewest reasonable execution sessions without overloading any one session. Include:

- recommended number of sessions
- tasks assigned to each session
- why the grouping keeps session count low safely
- context-load risk checks for each session
- handoff notes between sessions

Default to fewer, stronger sessions. Split only when context size, risk, or dependency complexity justifies it.

## Additional Operator Input

State how you interpreted and applied `$ARGUMENTS`. If none was provided, write: "No additional operator input provided."

## Decision Points For Operator

List only decisions still needed before execution. For each one, include:

- recommended default
- impact of choosing differently

Output rules:

- be concrete and execution-oriented
- do not write code
- do not omit any task
- avoid generic advice
