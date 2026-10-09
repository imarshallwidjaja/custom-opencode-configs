---
name: subagent-delegation
description: Use when the Cursor parent Agent has classified work as delegated or needs to coordinate named subagent lanes.
---

# Subagent Delegation

## Purpose

Execute the default Agent Rules' delegation-first policy with named Cursor subagents. The Rules own direct versus delegated classification and the specialist seats; this skill owns lane setup, scheduling, recovery, and integration detail. There is no exact-one-read or exact-one-write quota and no blanket delegation quota.

## Start A Lane

1. Select the named specialist from the default Agent Rules.
2. Give one primary goal to one direct child in a fresh separate context.
3. Record lane state, dependencies, owned paths, and required verification in the parent working context.
4. Send a self-contained handoff. Critical instructions must be present even when they also appear in User Rules because child propagation is not guaranteed.
5. Treat the child as terminal. Worker and reviewer agents perform no recursive delegation; the parent owns synthesis.
6. After a child returns, make every follow-up a fresh child, including review fixes. Do not resume the old session.

## Scheduling Rules

- Launch independent read-only seats in one message. A later seat waits only when it needs an earlier result. Blocking does not mean serial.
- Run disjoint writing lanes together only when they do not share writable files, state, migrations, generated outputs, or a live runtime.
- Separate context is not filesystem isolation. Cursor children share the checkout unless the parent gives them a separate working directory.
- In a shared checkout, writers with disjoint paths use one writing lane per owned path.
- Overlapping writers use a git worktree or isolated copy. If that copy cannot be created, report the blocker. Do not silently write a shared checkout another writer occupies.

## Lane Prompt Requirements

Each Cursor subagent or lane prompt must be self-contained and Cursor-native. Do not require OpenCode task-tool semantics unless the user is explicitly asking about OpenCode. Hand the child the target root, scope, and pointers to governing instructions, not pasted bodies. Separate operator requirements, specialist findings, and agent-chosen procedure in that handoff: pass the binding requirements and the evidence, and label procedure the parent chose as procedure.

- Objective and expected output
- Goal and acceptance criteria
- Target root
- Files or areas in scope
- Files or areas out of scope
- Known facts and evidence
- Prior failures, attempted path, errors, and likely cause
- Dependencies and assumptions
- Constraints and file ownership
- Pointers to governing instructions
- Verification commands expected for that lane
- Required final summary format
- Prose contract: require the child to load and apply `writing-policy`. Parent-loaded skills do not propagate. State artifact, audience, voice, and any additional depth or domain writing skills. Include this because rules do not propagate to children.
- Instruction to stop and report blockers rather than guessing on unsafe decisions

## File Ownership

For writing Cursor subagents or lanes, assign ownership up front:

- One lane owns each writable file or directory.
- Shared generated files need one owner or a serial integration step.
- Documentation and code that describe the same behavior should either be owned by one lane or integrated serially.
- The parent does not duplicate a delegated lane's implementation. It inspects the returned evidence and actual diff for synthesis and integration. Bounded direct reads stay allowed.

## Cursor Execution Models

- Give each named Cursor subagent a separate self-contained prompt and explicit file ownership.
- True write isolation requires a separate worktree, isolated project copy, cloud environment, or other separate working directory. A Git branch or separate assistant session does not isolate files.
- Overlapping writers use a git worktree or isolated copy. If that copy cannot be created, report the blocker. Do not silently write a shared checkout another writer occupies.
- Direct shared-checkout edits remain valid for an explicit operator request to continue existing uncommitted work, a small mechanical edit on a clean tree with no overlapping writer, or work already inside the isolated directory.
- Keep the parent as integration owner, responsible for reading final summaries, inspecting diffs, resolving conflicts, and running combined verification.

## Failure Handling

- Every follow-up after a returned child is a fresh child, including review fixes and retries. Do not resume the old session.
- If a lane fails, start a fresh named subagent instead of resuming the failed one.
- Pass concise failure context: the attempted path, where it failed, relevant errors, and the likely cause.
- If a child may still be running, wait until it returns. Do not send another prompt into that session or launch an overlapping writer.
- Do not let a failed lane block unrelated independent lanes.
- Resolve all lanes before review, integration, cleanup, or final reporting.

## Integration

After lanes finish:

- Read each final summary. Worker prose is not integrated acceptance.
- Materialize or integrate isolated results into an integration workspace before assessing the combined change.
- Do not run installs, builds, formatters, generators, or tests in a directory a live writer still occupies.
- Run combined verification in the integration workspace once no live writer occupies it.
- Record the command and the observed output before integrating.
- Inspect status and the actual diff, not only the reports.
- Collect required reviews of the settled candidate before remediation. Send that candidate through `code-reviewer`, then a proportional `simplicity-reviewer` pass. Add `vulnerability-reviewer` when the operator requested that scope. Reviewer severity does not decide acceptance.
- Give the follow-up child the prior and current candidate, the findings to close, and the pertinent evidence. That follow-up is a fresh child. Do not resume the returned session.
- Re-review when a fix invalidates evidence or a required review is missing. Stop when required reviews and applicable checks hold.
- Resolve conflicts intentionally and rerun affected checks.
- Commit only under the user's existing workflow contract and only with the recorded command output.
- Cleanup isolated working directories and temporary artifacts only after integration, verification, diff review, and review gates are complete.
- Prefer squash-style integration when it keeps main history compact and worker commit churn is not useful. Preserve branch history only when the topology itself carries useful information or the user asks for it.

## Red Flags

- Prompts that require hidden conversation context.
- Pasted bodies of governing instructions where a path and scope would do.
- Multiple lanes with write access to the same file.
- Parallel lanes that depend on the same generated artifact.
- A second Scout sent to check the first Scout.
- Resuming a returned child session.
- Treating a lane's prose as integrated acceptance without the recorded command output.
- Running installs, builds, formatters, generators, or tests in a directory a live writer still occupies.
- Remediation that starts before required reviews of the settled candidate.
- Recursive delegation by a worker or reviewer.
- Parent implementation that duplicates an active or completed delegated lane.
