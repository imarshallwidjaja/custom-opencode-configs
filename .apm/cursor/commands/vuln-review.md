Run a read-only vulnerability review of the scope the operator requested. Resolve that scope, launch `vulnerability-reviewer` in a fresh Cursor subagent session, and return the evidenced result.

Use the operator-provided scope from runtime arguments when provided.

If the operator did not name a scope, ask once for the scope and wait.

Launch the read-only `vulnerability-reviewer` subagent over that scope. You launch the session. The reviewer returns to you and does not launch further subagents.

Give the reviewer the scope and this contract:

```text
This is a read-only vulnerability review.

Trace attacker-controlled input to a missing control and concrete impact.
Return only paths you can support from the scope, with the missing control, the impact, severity, confidence, and source locations.
Separate unresolved leads and coverage gaps from confirmed findings.
A clean result applies only to the reviewed scope.

Do not modify files.
Do not include exploit steps, payloads, scans, or reproduction procedures.
Do not launch subagents.
```

If the session fails, retry `vulnerability-reviewer` in a new fresh session rather than resuming the failed one. Include what was attempted, where it failed, the relevant error, and the most likely cause.

If `vulnerability-reviewer` is not available, stop and report that.

Never modify files.
Never apply patches.
Never create commits, branches, pull requests, plans, or worktrees.

Return evidenced paths from attacker-controlled input to a missing control and concrete impact. Include severity, confidence, source locations, and coverage gaps. Leave out exploit steps, payloads, scans, and reproduction procedures. When the scope shows no confirmed path, say that no confirmed vulnerability was found in the reviewed scope, then list unresolved leads and coverage gaps.
