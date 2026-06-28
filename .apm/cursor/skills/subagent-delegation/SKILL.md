---
name: subagent-delegation
description: Use when splitting work across Cursor subagents, assistant sessions, or lanes; schedules independent work in parallel and dependent work serially with self-contained prompts and file ownership.
---

# Subagent Delegation

## Purpose

Split work safely across Cursor subagents where available, or across multiple assistant sessions or lanes when that is the available execution model, without losing ownership, context, or verification quality.

## Scheduling Rules

- Run independent lanes together when they do not share files, state, migrations, generated outputs, or ordering constraints.
- Run dependent lanes serially when one lane needs another lane's output, branch, schema, artifact, or decision.
- Prefer fewer lanes when file ownership is unclear.
- Do not start parallel writing lanes that can edit the same files unless ownership is explicitly assigned.

## Lane Prompt Requirements

Each Cursor subagent or lane prompt must be self-contained:

- Goal and acceptance criteria
- Files or areas in scope
- Files or areas out of scope
- Dependencies and assumptions
- Verification commands expected for that lane
- Required final summary format
- Instruction to stop and report blockers rather than guessing on unsafe decisions

## File Ownership

For writing Cursor subagents or lanes, assign ownership up front:

- One lane owns each writable file or directory.
- Shared generated files need one owner or a serial integration step.
- Documentation and code that describe the same behavior should either be owned by one lane or integrated serially.

## Cursor Execution Models

- If Cursor has native subagents, give each lane a separate self-contained prompt and explicit file ownership.
- If Cursor does not provide true subagent isolation, use separate branches, worktrees, or assistant sessions for writing lanes.
- If neither isolation nor clear ownership is available, run the work serially.
- Keep one integration owner responsible for reading final summaries, inspecting diffs, resolving conflicts, and running combined verification.

## Failure Handling

- If a lane fails, retry in a fresh session instead of resuming the failed one.
- Pass concise failure context: what was attempted, where it failed, relevant errors, and the likely cause.
- Do not let a failed lane block unrelated independent lanes.
- Reconcile completed lanes before starting dependent integration work.

## Integration

After lanes finish:

- Read each final summary.
- Check the actual diff, not only the report.
- Run integration-level verification for the combined change.
- Resolve conflicts intentionally and rerun affected checks.

## Red Flags

- Prompts that require hidden conversation context.
- Multiple lanes with write access to the same file.
- Parallel lanes that depend on the same generated artifact.
- Treating a lane's success report as verification without running an appropriate check.
