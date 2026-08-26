---
name: subagent-delegation
description: Use when the Cursor parent Agent has classified work as delegated or needs to coordinate named subagent lanes.
---

# Subagent Delegation

## Purpose

Execute the default Agent Rules' delegation-first policy with named Cursor subagents. The Rules own the direct-work threshold and specialist defaults; this skill owns lane setup, scheduling, recovery, and integration detail.

## Start A Lane

1. Select the named specialist from the default Agent Rules.
2. Give one primary goal to one direct child in a fresh separate context.
3. Record lane state, dependencies, owned paths, and required verification in the parent working context.
4. Send a self-contained handoff. Critical instructions must be present even when they also appear in User Rules because child propagation is not guaranteed.
5. Treat the child as terminal. Worker and reviewer agents perform no recursive delegation; the parent owns synthesis.

## Scheduling Rules

- Run independent read-only lanes or disjoint lanes together when they do not share writable files, state, migrations, generated outputs, or ordering constraints.
- Run dependent work serially when one lane needs another lane's output, branch, schema, artifact, or decision.
- Prefer fewer lanes when file ownership is unclear.
- Separate context is not filesystem isolation. Cursor children share the checkout unless the parent explicitly gives them a separate working directory.
- In the shared checkout, use one writing lane per owned path with disjoint ownership and no overlapping writers. If ownership overlaps, run the writers serially.

## Lane Prompt Requirements

Each Cursor subagent or lane prompt must be self-contained and Cursor-native. Do not require OpenCode task-tool or `subagent_type` semantics unless the user is explicitly asking about OpenCode.

- Objective and expected output
- Goal and acceptance criteria
- Files or areas in scope
- Files or areas out of scope
- Known facts and evidence
- Prior failures or attempted fixes
- Dependencies and assumptions
- Constraints and file ownership
- Verification commands expected for that lane
- Required final summary format
- Instruction to stop and report blockers rather than guessing on unsafe decisions

## File Ownership

For writing Cursor subagents or lanes, assign ownership up front:

- One lane owns each writable file or directory.
- Shared generated files need one owner or a serial integration step.
- Documentation and code that describe the same behavior should either be owned by one lane or integrated serially.
- The parent does not duplicate a delegated lane's reads, patches, or implementation. It inspects the returned evidence and actual diff for synthesis and integration.

## Cursor Execution Models

- Give each named Cursor subagent a separate self-contained prompt and explicit file ownership.
- True write isolation requires a separate worktree, isolated project copy, cloud environment, or other separate working directory. A Git branch or separate assistant session does not isolate files.
- If neither a separate working directory nor disjoint ownership is available, run the work serially.
- Keep the parent as integration owner, responsible for reading final summaries, inspecting diffs, resolving conflicts, and running combined verification.

## Failure Handling

- If a lane fails, start a fresh named subagent instead of resuming the failed one.
- Pass concise failure context: what was attempted, where it failed, relevant errors, and the likely cause.
- Do not blindly resume. A redirected still-running lane needs explicit failure context and a clear reason.
- Do not let a failed lane block unrelated independent lanes.
- Resolve all lanes before review, integration, cleanup, or final reporting.

## Integration

After lanes finish:

- Read each final summary.
- Materialize or integrate isolated results into an integration workspace before assessing the combined change.
- Run combined verification in the integration workspace.
- Inspect status and the actual diff, not only the reports.
- Resolve conflicts intentionally and rerun affected checks.
- Send completed non-trivial code through `code-reviewer`.
- Run a proportional `simplicity-reviewer` pass after code review.
- Send accepted findings to a fresh writer session with updated ownership and done criteria, then inspect and verify again.
- Commit only under the user's existing workflow contract and only with fresh evidence.
- Cleanup isolated working directories and temporary artifacts only after integration, verification, diff review, and review gates are complete.

## Red Flags

- Prompts that require hidden conversation context.
- Multiple lanes with write access to the same file.
- Parallel lanes that depend on the same generated artifact.
- Treating a lane's success report as verification without running an appropriate check.
- Recursive delegation by a worker or reviewer.
- Parent implementation that duplicates an active or completed delegated lane.
