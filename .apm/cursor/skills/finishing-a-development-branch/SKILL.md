---
name: finishing-a-development-branch
description: Use when implementation is complete and verified; presents safe git integration choices for merge, pull request, preservation, or discard.
---

# Finishing A Development Branch

## Overview

Complete development work by verifying the branch, presenting clear git options, and executing only the user's chosen path.

## Step 1: Verify

Before presenting completion options, run the relevant test, build, lint, or file-specific validation commands for the change.

If checks fail, stop and report the failures. Do not offer merge or pull request options until the branch is in a known state.

## Step 2: Inspect Git State

Run:

```bash
git status --short
git log --oneline --decorate -10
git diff --stat <base-branch>...HEAD
git diff <base-branch>...HEAD
```

Identify the likely base branch with repository conventions or `git merge-base` against common base branches such as `main` or `master`.

Inspect the branch diff before recommending merge, pull request, or discard actions. Status and recent commits are not enough because they do not show the actual content being integrated or removed.

## Step 3: Present Options

If the user already chose an exact integration and cleanup path, or the integration authority was settled before the work was placed (for example an approved local commit or squash path), skip this menu and execute that authorization after the required checks. Existing authorization satisfies confirmation for the named branches, worktrees, and actions; ask again only if the scope changed, ownership is uncertain, or new destructive risk was not covered. When no commit permission exists, do not commit to reach a menu choice: integrate as uncommitted changes only when the destination holds no conflicting user work, and otherwise ask at this decision.

Before integrating a worker's result (a commit, or an uncommitted change set applied to the destination), compare the destination path, full ref, and commit immediately before you integrate with the checkpoint A recorded when the work was placed, or with the newer target T when a reconciliation already merged T. Integrate only the verified source pin the worker returned, not a HEAD you discovered later. If the destination moved in a way that touches the change, overlaps it, or cannot be judged, stop. When the same path and ref moved, record the newly observed target T (path, full ref, immutable commit) separately from A. With commit authority, after the previous writer has ended, a fresh `forager` gets a reconciliation assignment carrying A, the current verified source pin S, and T (see `subagent-delegation`): it merges T's commit into S without rewriting source history and returns a fresh pin S'; the combined delta is reviewed and S' is verified before integration. Without commit authority, no worker merges or commits; settle the drift with the operator. A different path or ref, or unrelated history, also stops for an operator decision. Never overwrite A or T with a later observation: a further move needs a new decision and a new checkpoint.

Declare the history intent for each repository before integrating:

- **Private history**: unpublished commits created for this work under authority settled before placement. It may be squashed into one polished commit, or rebased when every commit is independently valuable.
- **Published history**: any source commit already pushed, shared, or relied on elsewhere. Its ancestry must survive: integrate it with a normal merge that keeps those commits and their messages. Never recreate it by squash, rebase, cherry-pick, or message rewriting.

With several repositories, keep a map from repository to its checkpoint A, any newer target T kept separately, and its verified pin, integrate and check each one, and report each outcome separately, including partial ones. Nothing here is atomic.

When no integration path is authorized yet, present these choices plainly:

1. Merge back to the base branch locally.
2. Push and create a pull request.
3. Keep the branch and worktree as-is.
4. Discard this work.

Do not choose for the user unless they already gave explicit instructions.

## Step 4: Execute The Choice

### Merge Locally

- Confirm the branch diff matches the intended change before switching branches.
- Switch to the base branch.
- Update it if the user expects that workflow.
- Integrate by the declared history intent: squash private history when worker commit churn is not useful, or merge published history normally (for example `git merge --no-ff <branch>`). A worktree commit does not authorize this step by itself.
- Run verification again on the merged result.
- For published history, run `git merge-base --is-ancestor <published-tip> <destination>` and require exit status 0. File-tree equality does not prove ancestry. If the check fails, stop and keep the source branch and worktree.
- Delete the development branch and worktree only after the merge, verification, and any required ancestry check succeed.

Cursor's `/apply-worktree` brings a worktree's changes into the main checkout. This package has no observable proof that it preserves commits or ancestry, so use it only for private history, and run the ancestry check above whenever published commits are involved.

### Push And Create Pull Request

- Inspect the diff and commit list before pushing.
- Push the branch.
- Create a pull request with a concise summary and test plan.
- Keep the branch available for review.

### Keep As-Is

- Report the branch name and worktree path.
- Do not delete anything.

### Discard

- Inspect the branch diff before asking for discard confirmation.
- Require explicit confirmation before deleting commits, branches, or worktrees.
- State exactly what will be removed.
- Do not use destructive commands without confirmation.

## Rules

- Do not merge with failing checks unless the user explicitly accepts the risk.
- Do not force-push unless explicitly requested.
- Do not delete branches or worktrees without confirmation.
- Do not include unrelated changes in a commit, merge, or pull request.
- Do not stash, revert, or commit the user's existing changes in the destination without explicit permission.
- Do not squash, rebase, or cherry-pick commits that are already published.

## Completion Report

Report:

- Chosen option and declared history intent
- Branch, base branch, and for each repository the checkpoint A, any reconciled target T, and the source commit
- Commands run
- Verification result, and the ancestry check output for published history
- Remaining branch or worktree state
