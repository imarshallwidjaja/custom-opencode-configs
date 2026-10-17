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

## Integration Authority

Settle integration authority before the first placement, because a worktree, an isolated copy, or a returned commit grants none.

- When the operator or the repository workflow already authorizes a local commit or a squash into the target branch, the parent executes that path at integration without asking again, and the lane handoffs say whether a worker commits.
- Without commit authority, integrate the verified result as uncommitted changes only when the destination holds no conflicting user work. When that is not safe, ask the operator at this decision, before any worker starts, not at the end.
- The decision follows each lane through dispatch, recovery, result consumption, reconciliation, integration, and closure. A lane without commit authority never gains it from a failure, a retry, or a successor, and its workers leave the work uncommitted.
- Existing user changes in the destination are the operator's. Preserve them, and never stash, revert, or commit them without explicit permission.
- Push, pull request, publish, and release each need their own explicit request.

Standing operator requirements, and any skill the operator named as required, are copied verbatim into every affected handoff; Cursor has no register that carries them.

## Build the Lane Inventory

Choose boundaries in this order:

1. Identify coherent, independently verifiable outcomes. Keep tightly coupled code, tests, documentation, and generated artifacts together.
2. Name each concrete predecessor output or capability decision. If a handoff cannot be stated, keep the work together or recommend a separately authorized plan.
3. Assign one owner for each module or path and each shared resource: generated outputs, external mutable resources, fixed-path test fixtures, ports, databases, and containers. Separate worktrees do not isolate these resources. Use one owner or sequence access.
4. Define done criteria, binding repository or operator checks, required early or pre-merge gates, lane verification, reviews required by the Cursor parent rules, and deterministic integration order. Name any integrated-only obligation in the lane inventory with its owner, prerequisite, command, and expected signal.
5. Add dependency edges and derive ready waves only after those contracts are clear.

Record each lane's purpose, specialist and owner, inputs and handoffs, path and resource ownership, done criteria, verification, review contract, dependencies, integration order, and whether the parent waits for it. The parent working context is enough. Do not create an evidence ledger.

## Waves, Dispatch, and Integration

Create only lanes whose handoffs are available, close to dispatch. A code dependency needs the verified predecessor integrated so the successor base contains the code: with commit authority that is a committed, integrated predecessor; without it, the successor runs in the checkout that holds the predecessor's verified uncommitted result after the predecessor's writer has finished. A report or decision dependency may use an inspected concrete handoff without a source revision.

Parallel writers need separate placements: Cursor's native isolation (isolated subagent worktrees, or `/worktree`) when it is exposed and the child's separate directory and branch are confirmed, otherwise a git worktree the parent creates through `using-git-worktrees`, or an isolated project copy when the parent rules select a copy. A subagent's separate context alone never isolates writes. Writes and fix passes inside one placement stay sequential. Separate placements do not isolate ports, databases, containers, fixed-path fixtures, or other shared runtime resources. Those keep one owner or sequenced access. Read-only scout, advisor, and reviewer lanes need no extra worktree. Reviews target settled source.

For each ready wave, launch every independent lane in the same assistant message. `subagent-delegation` supplies the handoff. Waiting for results is not a reason to send independent lanes one at a time.

The Cursor parent owns merge and cleanup. Follow `using-git-worktrees` for removal, including its authorization rule. Lane changes receive the reviews required by the Cursor parent rules. This skill adds no separate reviewer-approval gate. Before remediation and closure, accept supported material corrections, resolve material questions, and preserve usable unaffected review coverage. Required review, repository or operator checks, and lane verification each gate merge. Integrate accepted lanes in stable topological order, using inventory order to break ties. Schedule shared fixtures, ports, databases, containers, external resources, and verification so separate processes cannot collide. Batch live checks only when their prerequisites and mutable state are compatible, and serialize stateful checks that share state.

Run the selected integrated acceptance against the integrated result, including binding repository or operator checks and every integrated obligation named in the lane inventory. Do not impose an unrelated full suite when repository policy and impact do not require it. If no gate catalogue exists, inspect scripts, CI, and test owners. Uncertain impact selects a broader coherent existing check, and any missing check is reported. Capture actual output and the tested candidate plus relevant fixtures, configuration, generated artifacts, or live state. Worker prose alone is not evidence, and a branch result does not prove the integrated result.

After a correction, preserve the failure, verify the owning regression, and rerun affected consumer and integrated checks. Retain unaffected results only with a short non-impact reason. An unexplained green retry does not resolve an intermittent failure. Required skipped, unrun, failed, or blocked checks are not passing. If the session ends with a required obligation outstanding, report the batch incomplete.

Creating or merging a worktree does not commit the source changes and does not assign a worker. The parent commits only when the operator or the active workflow contract asks for a commit.

Before dispatch, record the branch, commit, and placement path (plus the dirty and untracked state when the placement is a shared checkout), and include that identity in the lane handoff. Reinspect after each writing handoff, before reviews and remediation, after a sibling integrates or the destination moves, and before integration. Pass the recorded identity through unchanged. Relevant, overlapping, or uncertain drift stops the lane. After the previous writer is finished, a fresh worker reconciles in that same placement. Integrate the verified result under the lane's commit authority. With commit authority, merge the pinned commit into the clean integration checkout. Without it, apply only the attributable changed and untracked files of the verified dirty candidate to the destination when it holds no conflicting user work. Adapt and review the combined delta, verify it, and record the integrated result's identity (the new source commit, or the base identity plus the applied file set) and the target identity used. When more than one repository is in the batch, report each repository's outcome on its own. Do not describe that integration as atomic.

The parent performs a single direct read itself when one status check, one worktree inspection, or one known diff answers the question. For multi-step forensics, such as comparing drift or assembling evidence from an interrupted worker, launch one fresh scout with one named question and the known placement, source, and destination identities, and expect source observations only. The parent spot-checks decisive cited revisions before acting and does the reasoning. A discovered HEAD is observed, not a verified source pin. The parent owns acceptance, termination, retry, integration, cleanup, and the lane inventory. Preserve the placement until the parent resolves lifecycle and ownership uncertainty. Retry a failed lane in a fresh subagent with the attempted approach, the failure point, the relevant errors, and the likely cause.

Every child returns one terminal report, and a returned result that is empty, partial, blocked, or unsatisfactory is still terminal. Review findings, retries, and new evidence are fresh assignments in the same lane, in the same placement once the previous writer is finished. Continue a child session only on an explicit operator instruction or a native interrupted-session mechanism, never on an inference from its ID or status.

## Interrupted Writer Recovery

A provider failure, a lost connection, an application restart, or a missing return can end a writer without a trustworthy report. A failed run does not fail the lane.

1. Confirm the prior writer is terminated, along with any subprocess or shared-resource effect that could still change the placement or external state, before any overlapping execution. A cancellation request, a closed transcript, an idle application after restart, or silence does not establish termination. While termination is uncertain, wait or ask the operator; launch no replacement.
2. Inspect before any cleanup and preserve the failure evidence: the error and its source, the retained placement, observed source HEAD, destination identity, and dirty and untracked state.
3. Treat what survived as attributed evidence. A report written before the failure is the prior worker's narrative, not proof of completion. A HEAD you discover is observed, not a verified pin. Do not fabricate or transcribe a terminal report.
4. Launch a fresh worker in the same retained placement. Its handoff states the stopped-writer evidence, the candidate and dirty state with what is attributable to the prior worker, the authorized scope, required checks, the destination checkpoint duty, and the result to return under the lane's original commit authority. Authorize adoption only of edits proven to come from the prior worker; dirty files are not worker-owned merely because they sit in the placement. Preserve unrelated or ambiguous edits, ignored dependencies and build output, and external resources, and never reset or clean the whole tree.
5. The successor checks, adopts, or completes only the authorized edits, verifies them, labels reconstructed accounts, and returns the result under the lane's original commit authority. With commit authority, that is a commit it verified in its own session: a new commit, or the existing candidate when it needed no edits. Without it, the successor creates no commit and returns the base identity, the attributable changed and untracked files, and the checks it ran against that dirty tree; it never describes HEAD as covering the uncommitted result.


## Closure

A lane closes only after applicable terminal observation, result consumption, required review and lane verification, integration (the merged commit, or the applied uncommitted change set) or an explicit no-change or discard decision, and cleanup are recorded. The batch closes only after every lane is closed and selected integrated acceptance, including every named obligation, has applicable passing evidence recorded. Stop once required evidence and reviews suffice. Run more checks only for a named gap, invalidation, or new risk.

## Provenance

Locally maintained Cursor adapter of the `orchestrating-ad-hoc-work` skill and the interrupted-worker recovery and review follow-up guidance in Agent Hive (`oc-arkive` package 5.0.0, commit `e1d968c5e53cdb03c95849b32b7bc9cbb7de47fc`). The lane, wave, recovery, and closure invariants are adapted by hand; Hive tools, state, and background boards are not carried. This skill is not synced, so `scripts/sync-cursor-hive-skills.py` never overwrites it.
