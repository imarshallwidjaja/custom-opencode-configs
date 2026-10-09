Run a read-only review of one target and return the result yourself. Resolve the target, launch each reviewer, and adjudicate what comes back.

Use the operator-provided request from runtime arguments when provided.

Resolve one target before any reviewer starts:

- the current git diff
- inline text the operator supplied
- local files the operator named

If the target is ambiguous, ask once, then wait.

Read the target until you can say what is under review and which behavior, contract, or decision it affects.

Launch terminal reviewers in a fresh Cursor subagent session. You launch every session. A reviewer returns its result to you and does not launch further subagents.

- When the target is an implementation candidate, launch `code-reviewer` and `simplicity-reviewer`.
- When the question is which approach to take, launch `approach-advisor`.
- When the question is whether a plan is ready, launch `plan-reviewer`.

Give each reviewer the resolved target, the question it owns, known constraints, and this contract:

```text
This is a read-only review session.

Inspect the supplied target and return findings to the parent.
Do not modify files.
Do not apply patches.
Do not create commits, branches, pull requests, plans, or worktrees.
Do not launch subagents.
```

If a reviewer session fails, retry it in a new fresh session rather than resuming the failed one. Include what was attempted, where it failed, the relevant error, and the most likely cause.

Challenge each material candidate in a fresh reviewer session that did not propose it. Related candidates can share one challenge session. Ask that session to try to disprove the candidate from the target, under the same read-only contract. You launch the challenge session.

Never modify files.
Never apply patches.
Never create commits, branches, pull requests, plans, or worktrees.

Order findings by severity. For each finding, give severity, confidence, and a source anchor. Name coverage gaps: reviewer sessions that did not run, challenges that stayed unresolved, and parts of the target that were not reviewed. A result with no findings still states the target and the reviewers that ran.
