---
name: agents-md-mastery
description: Use when bootstrapping, reviewing, or pruning AGENTS.md and other durable Cursor agent instructions.
---

# AGENTS.md Mastery

AGENTS.md is durable behavioral memory. Every entry should change how a future agent acts. Quality matters more than completeness.

**Core rule: evidence before durable instructions.** One-off preferences may be captured provisionally in the existing scratchpad, but only after an exact proposal and item-level approval. They must not be promoted to project AGENTS.md, global instructions, or Cursor User Rules until repeated or mature evidence shows they are useful.

## Signal Filter

Signal changes future behavior; noise only documents what an agent can already observe.

Keep instructions that:

- prevent a specific recurring mistake
- preserve a non-obvious convention or ownership boundary
- capture a hard-won safety rule or gotcha
- enable behavior an agent would otherwise miss

Reject descriptions of observable code, generic best practices, history, ticket notes, and one-off outcomes. Write observable behavior: name the trigger, required action, and mistake prevented.

## Scope

Read instructions from the workspace root down to the files in scope. A nested AGENTS.md owns narrower paths and may refine broader guidance. Place a rule at the narrowest scope where it remains true; do not promote repository-specific behavior to Cursor User Rules.

## Workflow

1. Gather evidence from the visible conversation, diffs, failures, repository, and existing instructions.
2. Classify each candidate as project instructions, nested instructions, scratchpad, Cursor User Rules, or not durable.
3. Re-read the proposed target and check for duplicates, conflicts, and stale wording.
4. Present exact proposed text, destination, evidence, and operation for every item.
5. Wait for item-level approval. Apply only accepted items and only to the approved target.
6. Show the resulting diff or manual handoff, then summarize applied, rejected, and unchanged items.

## Target Boundaries

Provisional one-off preferences stay in the existing scratchpad, not project instructions or Cursor User Rules. Promote them only after repeated cross-project evidence and explicit approval.

Only analyze conflicts in Cursor User Rules when the current Rules text is supplied or visible. If User Rules, a global file, or a scratchpad is unavailable, do not claim it was read or edited. After approval, return paste-ready text, manual instructions naming the destination, and a clear `not applied` status.

## Bootstrap, Review, And Prune

For bootstrap, add only the commands, conventions, scope boundaries, and gotchas that evidence supports. Keep the file short and put high-impact rules first.

For review, replace stale or conflicting guidance and merge true duplicates. Prune generic, observable, redundant, or disproven entries. Preserve hard-won safety and gotcha guidance unless evidence proves it obsolete or superseded; silence alone is not evidence that a safety rule is unnecessary.
