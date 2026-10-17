---
name: subagent-delegation
description: Use when the Cursor parent Agent has classified work as delegated or needs to coordinate named subagent lanes.
---

# Subagent Delegation

## Purpose

Execute the default Agent Rules' delegation-first policy with named Cursor subagents. The Rules own direct versus delegated classification, the specialist seats, review routing, and integration authority; this skill owns the handoff a child receives, lane setup, scheduling, recovery, and integration detail. `orchestrating-ad-hoc-work` owns the lane inventory, dependency waves, placement, and closure when a request has several outcomes. There is no exact-one-read or exact-one-write quota and no blanket delegation quota.

Children do not inherit your conversation, your loaded skills, or any guaranteed copy of User Rules. The handoff and the agent definition carry what a child needs.

## Start A Lane

1. Select the named specialist from the default Agent Rules.
2. Give one primary goal to one direct child in a fresh separate context. A goal may include tightly coupled code, tests, and docs; do not split it by file or step.
3. Record lane state, dependencies, owned paths, and required verification in the parent working context.
4. Send a self-contained handoff. Critical instructions must be present even when they also appear in User Rules, because child propagation is not guaranteed.
5. Treat the child as terminal. Worker and reviewer agents perform no recursive delegation; the parent owns synthesis.
6. After a child returns, make every follow-up a fresh child, including review fixes. Do not resume the old session.

## Scheduling Rules

- Launch independent read-only seats in one message. A later seat waits only when it needs an earlier result. Blocking does not mean serial.
- Separate context is not filesystem isolation. A Git branch does not isolate files.
- Parallel writing lanes each get their own git worktree or isolated copy. One writer may use the shared checkout when no other writer is active. If a separate placement cannot be created, report the blocker. Do not put two writers in one checkout, even on disjoint paths.
- Direct shared-checkout edits remain valid for a single writer: an explicit request to continue existing uncommitted work, a small mechanical edit on a clean tree with no other writer, or work already inside the isolated directory.
- Shared state, migrations, generated outputs, and a live runtime keep one owner or sequenced access. Separate worktrees do not isolate them.

## Lane Prompt Requirements

Each Cursor subagent or lane prompt must be self-contained and Cursor-native. Do not require OpenCode task-tool semantics unless the user is explicitly asking about OpenCode. Hand the child the target root, scope, and pointers to governing instructions, not pasted bodies. When a governing workspace root differs from the target root, pass it as its own field even when it lies above the Git repository; a child given only the repository may stop its instruction search there. Separate operator requirements, specialist findings, and agent-chosen procedure in that handoff: pass the binding requirements and the evidence, and label procedure the parent chose as procedure.

- Objective and expected output, with what done looks like
- Goal and acceptance criteria
- Target root, and the governing workspace root when it differs
- Files or areas in scope, and files or areas out of scope
- File ownership: the paths or worktree this child may change, and the paths concurrent siblings own
- Preserved contracts: behavior, interfaces, and persisted shapes that must not change
- Binding decisions in force, each with the reason the worker needs it; mark sketches and private hints as illustrative so the worker may adapt them
- Known facts and evidence with file and line references; do not write "based on your findings"
- Prior failures: the attempted path, where it failed, relevant errors, and the likely cause
- Dependencies and assumptions
- Constraints, including standing operator requirements copied verbatim
- Pointers to governing instructions
- Authority: the mission mode (implement, fix, refactor, or report-only diagnosis), whether the child commits and returns a source commit SHA, and the decisions made only in this session. A child without commit authority returns the base identity, its attributable changed and untracked files, and the checks it ran. In-place and diagnosis missions authorize no commit; merge, push, and cleanup stay with the parent
- Destination identity: the inspected path, full ref, and commit, and the instruction to reinspect it at coherent milestones and before returning
- Verification commands expected for that lane, and the candidate each result must cover
- Required skills, named exactly. The child loads each one itself, because parent-loaded skills do not propagate
- Required final summary format
- Prose contract: for a prose deliverable, state the artifact, audience, voice when specified, and the required writing skills, and require the child to load `unslop` and those skills itself
- Instruction to stop and report blockers rather than guessing on unsafe decisions; a child cannot ask the operator, so it returns the question

When key facts are unknown, assign bounded discovery first. On a retry, state the failed approaches, the findings and requirements the new child must meet, and any operator decisions directly in the handoff, not only behind a report reference.

Shape of a worker handoff (fictional repository):

```text
Goal: loadClientConfig (packages/client/src/config.ts:30-58) throws ConfigError('invalid_timeout') for a negative timeoutMs. Done = the new case passes and valid configurations load as before.
Scope: packages/client/src/config.ts and config.test.ts in /work/client. packages/server has its own loader and stays untouched.
Preserve: ConfigError codes, the exported loadClientConfig signature, the default timeoutMs of 30000.
Binding decision: the check lives in loadClientConfig because the socket layer must not learn configuration rules. The error-message wording is illustrative.
Checks: run the package test file and type-check; report their output with the commit you tested.
Authority: fix and commit in /work/client and return the exact commit SHA. Do not merge, push, or clean up.
Destination: /work/client, refs/heads/main, 9f3c2a1. Reinspect before returning and report any movement that touches config.ts.
```

## Reviewer Packets

Reviewers and advisors do not inherit your context either. For an implementation review, give each reviewer the target root and candidate (ref, commit, or supplied material), the base so removed code stays visible, the paths under review, and pointers to governing requirements: operator requirements, instruction files, and required skills with their scope. Add a review packet so the reviewer can judge how the change fits the system, and keep it focused:

- Purpose: what the change must achieve, with acceptance criteria or the plan reference.
- Boundaries: contracts, interfaces, or persisted shapes the change touches, with known consumers, sibling implementations, and owning tests as paths or symbols.
- Lenses: skills or project rules that bear on this change beyond the required ones.
- Leads: concerns you noticed in the worker report or diff, each with an anchor and the question that would settle it, marked unverified. Leads direct attention without narrowing the reviewer's scope.
- Evidence: the worker's verification commands and results, stated deviations, and known risks.
- Re-review: prior findings with your decision on each, the prior review's coverage, the fix range (prior to current candidate), and what the fix can affect.

For an independent challenge on a high-risk surface, send an existing reviewer the same candidate with an explicit adversarial posture and name `adversarial-review` as a required skill. Do not invent a new reviewer.

## File Ownership

For writing Cursor subagents or lanes, assign ownership up front:

- One lane owns each writable file or directory.
- Shared generated files need one owner or a serial integration step.
- Documentation and code that describe the same behavior should either be owned by one lane or integrated serially.
- The parent does not duplicate a delegated lane's implementation. It inspects the returned evidence and actual diff for synthesis and integration. Bounded direct reads stay allowed.

## Cursor Execution Models

- Give each named Cursor subagent a separate self-contained prompt and explicit file ownership.
- True write isolation requires a separate worktree, isolated project copy, cloud environment, or other separate working directory. A Git branch or separate assistant session does not isolate files.
- Cursor documents isolated project copies for subagents (each in its own Git worktree and branch) and `/worktree` for a whole chat. Use them when they are exposed and you can confirm the child's directory and branch are separate; otherwise create the worktree yourself with `using-git-worktrees`. This package does not validate those documented capabilities, so confirm the placement instead of assuming it.
- Parallel writing lanes each get their own git worktree or isolated copy. One writer may use the shared checkout when no other writer is active. If a separate placement cannot be created, report the blocker. Do not put two writers in one checkout, even on disjoint paths.
- Direct shared-checkout edits remain valid for a single writer: an explicit request to continue existing uncommitted work, a small mechanical edit on a clean tree with no other writer, or work already inside the isolated directory.
- Keep the parent as integration owner, responsible for reading final summaries, inspecting diffs, resolving conflicts, and running combined verification.
- A scout that must understand a failure still only retrieves evidence; the parent reasons over it, and non-trivial diagnosis goes to `forager` or `approach-advisor` as a report-only mission.

## Failure Handling

- Every follow-up after a returned child is a fresh child, including review fixes and retries. Do not resume the old session.
- Continue an existing child session only when the operator explicitly asks for it or a native interrupted-session mechanism does; never infer that from an agent ID, a status, or a transcript.
- If a lane fails, start a fresh named subagent instead of resuming the failed one.
- Pass concise failure context: the attempted path, where it failed, relevant errors, and the likely cause.
- If a child may still be running, wait until it returns. Do not send another prompt into that session or launch an overlapping writer.
- If a writer ended without a trustworthy report, follow the interrupted-writer steps in `orchestrating-ad-hoc-work` before any replacement starts.
- Do not let a failed lane block unrelated independent lanes.
- Resolve all lanes before review, integration, cleanup, or final reporting.

## Integration

After lanes finish:

- Read each final summary. Worker prose is attributed evidence, not integrated acceptance; read any reported adaptations and design friction before accepting a green result.
- Materialize or integrate isolated results into an integration workspace before assessing the combined change.
- Do not run installs, builds, formatters, generators, or tests in a directory a live writer still occupies.
- Run combined verification in the integration workspace once no live writer occupies it.
- Record the command and the observed output before integrating, with the candidate it covered.
- Inspect status and the actual diff, not only the reports.
- Collect the reviews the Rules require for the settled candidate before remediation: `code-reviewer` and a proportional `simplicity-reviewer` pass for source changes, and `vulnerability-reviewer` when the operator requested that scope. Reviewer severity does not decide acceptance.
- Give the follow-up child the prior and current candidate, the findings to close, the fix diff, and the pertinent evidence. That follow-up is a fresh child.
- Re-review when a fix invalidates evidence, a material finding is newly supported, or a required review is missing. Stop when required reviews and applicable checks hold.
- Resolve conflicts intentionally and rerun affected checks.
- Commit only under the integration authority settled before placement and only with the recorded command output.
- Cleanup isolated working directories and temporary artifacts only after integration, verification, diff review, and review gates are complete.
- Prefer squash-style integration when it keeps main history compact and worker commit churn is not useful. Preserve branch history only when the topology itself carries useful information or the user asks for it.

## Red Flags

- Prompts that require hidden conversation context.
- Pasted bodies of governing instructions where a path and scope would do.
- Multiple lanes with write access to the same file.
- Parallel lanes that depend on the same generated artifact.
- A second Scout sent to check the first Scout.
- Resuming a returned child session, or inferring that continuation is allowed from an ID.
- Treating a lane's prose as integrated acceptance without the recorded command output.
- Running installs, builds, formatters, generators, or tests in a directory a live writer still occupies.
- Remediation that starts before required reviews of the settled candidate.
- Recursive delegation by a worker or reviewer.
- Parent implementation that duplicates an active or completed delegated lane.
- Treating worktree creation as permission to commit, merge, or push.

## Provenance

Cursor-only skill with no Hive source skill. Its worker and reviewer handoff fields adapt the worker-assignment, review-handoff, and review-follow-up guidance in the agent prompts of Agent Hive (`oc-arkive` package 5.0.0, commit `e1d968c5e53cdb03c95849b32b7bc9cbb7de47fc`) and the invariants of its parallel-dispatch skill, by hand and without Hive tools. This skill is not synced.
