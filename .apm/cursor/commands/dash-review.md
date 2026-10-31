Run a review of one target and return the result yourself. Resolve the target, launch each reviewer, and adjudicate what comes back. This is a source review: the reviewed source stays as found, and every reviewer stays read-only.

Use the operator-provided request from runtime arguments when provided.

Resolve one target before any reviewer starts:

- the current git diff
- inline text the operator supplied
- local files the operator named

If the target is ambiguous, ask once, then wait.

Read the target until you can say what is under review and which behavior, contract, or decision it affects.

Launch terminal reviewers in a fresh Cursor subagent session. You launch every session. A reviewer returns its result to you and does not launch further subagents.

A vulnerability-only request still belongs to `/vuln-review`. For every other request, choose the smallest useful reviewer set. Do not skip a reviewer the operator named, including `vulnerability-reviewer`.

- When the operator names the reviewers, launch each named reviewer.
- When the operator names no reviewer and the target is a source change, launch `code-reviewer` and `simplicity-reviewer` together on the same candidate. A bounded docs, tests, or mechanical edit gets `code-reviewer` alone.
- When the operator names no reviewer and the question is which approach to take, launch `approach-advisor`.
- When the operator names no reviewer and the question is whether a plan is ready, launch `plan-reviewer`.

Give each reviewer the resolved target and its root, the base or comparison range, the question it owns, the purpose or acceptance criteria when known, known constraints and the instruction files that govern the target, and leads marked unverified. Reviewers do not inherit your context. Add this contract:

```text
This is a read-only review session.

Inspect the supplied target and return findings to the parent.
Do not modify files.
Do not apply patches.
Do not create commits, branches, pull requests, plans, or worktrees.
Do not run installs, builds, tests, or other commands that write state; name a command that would settle a question for the parent to run.
Do not launch subagents.
```

When running the candidate would settle a material question that reading cannot, follow Runtime Exercise In Reviews from the default Agent Rules. Proceed only when an operator instruction already covers that exercise's purpose, candidate, and effects; then commission `investigator` under the Rules' Experiments section in the covered placement, with an evidence destination outside it. Otherwise ask the operator once and wait, or report the missing proof as a coverage gap. The investigator is not a reviewer: it adds nothing to reviewer participation, and its output is evidence you adjudicate.

If a reviewer session fails, retry it in a new fresh session rather than resuming the failed one. Include what was attempted, where it failed, the relevant error, and the most likely cause.

Challenge each material candidate in a fresh reviewer session that did not propose it. Related candidates can share one challenge session. Ask that session to try to disprove the candidate from the target, under the same read-only contract. You launch the challenge session.

Never modify the reviewed source.
Never apply patches.
Never create commits, pull requests, or plans. Outside an authorized runtime exercise, never create branches or worktrees.

Adjudicate on evidence: spot-check the quoted anchor of each material finding, keep findings that survive the challenge, and report optional suggestions only as optional. Order findings by severity. For each finding, give severity, confidence, and a source anchor. Name coverage gaps: reviewer sessions that did not run, challenges that stayed unresolved, parts of the target that were not reviewed, and runtime proof that was needed but not authorized. A result with no findings still states the target and the reviewers that ran.
