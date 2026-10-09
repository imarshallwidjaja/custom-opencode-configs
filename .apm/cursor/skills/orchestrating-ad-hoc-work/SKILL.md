---
name: orchestrating-ad-hoc-work
description: Use when the Cursor parent coordinates ad-hoc work that may have multiple independently verifiable outcomes, dependency waves, shared write or runtime resources, or more than one worker attempt or turn.
---

# Orchestrating Ad-Hoc Work

## Scope and Trigger

Load this skill before creating a worktree or dispatching delegated work when a request may have multiple independently verifiable outcomes, dependency waves, shared write or runtime resources, or more than one worker attempt or turn. The Cursor parent coordinates that work. Decomposition may keep one coherent lane. One lane is a correct result. Do not split by file, step, or quota merely to create parallelism.

This skill owns outcome boundaries, the lane inventory, dependency waves, placement readiness, lane-level recovery coordination, result consumption, review and fix sequencing, deterministic integration, and closure. `subagent-delegation` owns named-subagent handoffs and scheduling detail. `parallel-exploration` owns read-only research fan-out.

Temporary worktrees and isolated copies are workspace placement only. They are not run history, evidence ledgers, or reports.

## Ad-Hoc Suitability

Stay ad-hoc when material scope, contracts, and risks are resolved, dependencies have concrete handoffs, and isolated runs can verify and integrate the work. Recommend a separately authorized plan when unresolved contracts, a handoff that cannot be stated, migration or irreversible risk, or an audit or governance need would make ad-hoc coordination materially less safe.

That recommendation is advisory. If the operator rejects it, continue ad-hoc only when material scope, contracts, and risks are otherwise resolved. If one remains unresolved, ask that concrete blocking question and do not create workers. Routine decomposition needs no approval question.

## Build the Lane Inventory

Choose boundaries in this order:

1. Identify coherent, independently verifiable outcomes. Keep tightly coupled code, tests, documentation, and generated artifacts together.
2. Name each concrete predecessor output or capability decision. If a handoff cannot be stated, keep the work together or recommend a separately authorized plan.
3. Assign one owner for each module or path and each shared resource: generated outputs, external mutable resources, fixed-path test fixtures, ports, databases, and containers. Separate worktrees do not isolate these resources. Use one owner or sequence access.
4. Define done criteria, binding repository or operator checks, required early or pre-merge gates, lane verification, reviews required by the Cursor parent rules, and deterministic integration order. Name any integrated-only obligation in the lane inventory with its owner, prerequisite, command, and expected signal.
5. Add dependency edges and derive ready waves only after those contracts are clear.

Record each lane's purpose, specialist and owner, inputs and handoffs, path and resource ownership, done criteria, verification, review contract, dependencies, integration order, and whether the parent waits for it. The parent working context is enough. Do not create an evidence ledger.

## Waves, Dispatch, and Integration

Create only lanes whose handoffs are available, close to dispatch. A code dependency normally needs a verified, committed, integrated predecessor so the successor base contains the code. A report or decision dependency may use an inspected concrete handoff without a source revision.

Parallel writers need separate placements owned by the Cursor parent: a git worktree created through `using-git-worktrees`, or an isolated project copy when the parent rules select a copy. Writes and fix passes inside one placement stay sequential. Separate placements do not isolate ports, databases, containers, fixed-path fixtures, or other shared runtime resources. Those keep one owner or sequenced access. Read-only scout, advisor, and reviewer lanes need no extra worktree. Reviews target settled source.

For each ready wave, launch every independent lane in the same assistant message. `subagent-delegation` supplies the handoff. Waiting for results is not a reason to send independent lanes one at a time.

The Cursor parent owns merge and cleanup. Follow `using-git-worktrees` for removal, including its authorization rule. Lane changes receive the reviews required by the Cursor parent rules. This skill adds no separate reviewer-approval gate. Before remediation and closure, accept supported material corrections, resolve material questions, and preserve usable unaffected review coverage. Required review, repository or operator checks, and lane verification each gate merge. Integrate accepted lanes in stable topological order, using inventory order to break ties. Schedule shared fixtures, ports, databases, containers, external resources, and verification so separate processes cannot collide. Batch live checks only when their prerequisites and mutable state are compatible, and serialize stateful checks that share state.

Run the selected integrated acceptance against the integrated result, including binding repository or operator checks and every integrated obligation named in the lane inventory. Do not impose an unrelated full suite when repository policy and impact do not require it. If no gate catalogue exists, inspect scripts, CI, and test owners. Uncertain impact selects a broader coherent existing check, and any missing check is reported. Capture actual output and the tested candidate plus relevant fixtures, configuration, generated artifacts, or live state. Worker prose alone is not evidence, and a branch result does not prove the integrated result.

After a correction, preserve the failure, verify the owning regression, and rerun affected consumer and integrated checks. Retain unaffected results only with a short non-impact reason. An unexplained green retry does not resolve an intermittent failure. Required skipped, unrun, failed, or blocked checks are not passing. If the session ends with a required obligation outstanding, report the batch incomplete.

Creating or merging a worktree does not commit the source changes and does not assign a worker. The parent commits only when the operator or the active workflow contract asks for a commit.

Before dispatch, record the branch, commit, and placement path, and include that identity in the lane handoff. Reinspect after each writing handoff, before reviews and remediation, after a sibling integrates or the destination moves, and before integration. Pass the recorded identity through unchanged. Relevant, overlapping, or uncertain drift stops the lane. After the previous writer is finished, a fresh worker reconciles in that same placement. Merge the pinned commit into the clean integration checkout, adapt and review the combined delta, verify it, and record the new source commit and the target identity used. When more than one repository is in the batch, report each repository's outcome on its own. Do not describe that integration as atomic.

The parent performs a single direct read itself when one status check, one worktree inspection, or one known diff answers the question. For multi-step forensics, such as comparing drift or assembling evidence from an interrupted worker, launch one fresh scout with one named question and the known placement, source, and destination identities. Spot-check decisive cited revisions before acting. Scout returns observations, hypotheses, and limits. A discovered HEAD is observed, not a verified source pin. The parent owns acceptance, termination, retry, integration, cleanup, and the lane inventory. Preserve the placement until the parent resolves lifecycle and ownership uncertainty. Retry a failed lane in a fresh subagent with the attempted approach, the failure point, the relevant errors, and the likely cause.

## Closure

A lane closes only after applicable terminal observation, result consumption, required review and lane verification, merge or an explicit no-change or discard decision, and cleanup are recorded. The batch closes only after every lane is closed and selected integrated acceptance, including every named obligation, has applicable passing evidence recorded. Stop once required evidence and reviews suffice. Run more checks only for a named gap, invalidation, or new risk.
