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
```

Identify the likely base branch with repository conventions or `git merge-base` against common base branches such as `main` or `master`.

## Step 3: Present Options

Present these choices plainly:

1. Merge back to the base branch locally.
2. Push and create a pull request.
3. Keep the branch and worktree as-is.
4. Discard this work.

Do not choose for the user unless they already gave explicit instructions.

## Step 4: Execute The Choice

### Merge Locally

- Switch to the base branch.
- Update it if the user expects that workflow.
- Merge or squash the development branch according to repository convention.
- Run verification again on the merged result.
- Delete the development branch only after the merge and verification succeed.

### Push And Create Pull Request

- Inspect the diff and commit list before pushing.
- Push the branch.
- Create a pull request with a concise summary and test plan.
- Keep the branch available for review.

### Keep As-Is

- Report the branch name and worktree path.
- Do not delete anything.

### Discard

- Require explicit confirmation before deleting commits, branches, or worktrees.
- State exactly what will be removed.
- Do not use destructive commands without confirmation.

## Rules

- Do not merge with failing checks unless the user explicitly accepts the risk.
- Do not force-push unless explicitly requested.
- Do not delete branches or worktrees without confirmation.
- Do not include unrelated changes in a commit, merge, or pull request.

## Completion Report

Report:

- Chosen option
- Branch and base branch
- Commands run
- Verification result
- Remaining branch or worktree state
