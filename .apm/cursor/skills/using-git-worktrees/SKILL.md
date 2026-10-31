---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current checkout; creates a git worktree with safe directory selection and baseline verification.
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces that share the same repository. Use them when feature work, risky fixes, or parallel branches should not disturb the current checkout.

## Native Isolation

Cursor documents its own isolation: a subagent asked to run in an isolated environment gets its own Git worktree and branch, and `/worktree` runs the rest of a chat in a separate checkout (`/apply-worktree` brings the result back, `/delete-worktree` removes it). When the session exposes these and you can confirm the child's directory and branch are separate from the parent's, use them. Otherwise create the worktree yourself as below. This package does not validate the documented behavior, so confirm the placement by inspecting the path and branch instead of assuming it. A project's `.cursor/worktrees.json` may define the setup commands Cursor runs for a native worktree.

Creating a worktree, natively or by hand, grants no authority to commit, merge, push, or delete anything. The integration authority settled before placement governs those actions.

## Cleanup And Evidence

Cursor can prune older worktrees automatically to limit disk use. Its documentation says the cleanup keeps only the newest worktrees up to a machine-wide cap across every workspace, and that worktrees created outside its manager, including ones made with `git worktree add` or `/worktree`, are eligible. Keep evidence, logs, and anything needed after a run outside every worktree, and record the path and branch of each worktree you rely on. Do not change Cursor's cleanup settings unless the operator asks.

The parent removes the temporary worktrees it created. An experiment worktree is removed once its execution has ended and its evidence is kept outside it; it is never merged. An implementation worktree is removed only after integration, verification, and any required ancestry check succeed. Ignored dependency installs and build output alone do not block removal; tracked or untracked changes do, so report them and keep the worktree.

## Directory Selection

Use this priority order:

1. Existing `.worktrees/` directory in the project.
2. Existing `worktrees/` directory in the project.
3. A project instruction file that specifies a worktree directory.
4. Ask the user to choose between a project-local ignored directory and a global location such as `~/.local/share/agent-worktrees/<project-name>/`.

If both `.worktrees/` and `worktrees/` exist, prefer `.worktrees/`.

## Safety Verification

For project-local directories, validate the actual selected worktree root before creating a worktree:

```bash
git check-ignore -q -- "$worktree_root"
```

If the chosen project-local worktree root is not ignored, fix that hygiene issue before creating the worktree. Do not validate only hardcoded defaults like `.worktrees` or `worktrees` when a different project-local root was selected.

Global directories do not need project ignore checks because they live outside the repository.

## Creation

Detect the project name:

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

Create the worktree:

```bash
git worktree add "$path" -b "$branch_name"
cd "$path"
```

For an experiment at a named commit, start the branch there:

```bash
git worktree add -b "$branch_name" "$path" "$commit"
```

Then apply the candidate's relevant staged and unstaged diff and copy its relevant untracked files, which a Git diff omits, so the placement matches the named candidate.

For a global location, use a path like:

```bash
path="$HOME/.local/share/agent-worktrees/$project/$branch_name"
```

## Baseline Setup

Use the project's own setup guidance before running install or dependency commands. Prefer `README`, contributor docs, lockfile/package-manager conventions, or toolchain files over generic defaults.

Run only the setup command the project documents or clearly implies, such as `bun install`, `npm ci`, `pnpm install`, `poetry install`, `uv sync`, `cargo fetch`, or `go mod download`. If no setup command is documented or implied, skip dependency mutation and report that no setup command was run.

Then run the nearest documented baseline check. If the project has no documented check, infer the smallest safe read-only or low-cost validation command from local conventions rather than running broad or expensive suites by default.

If baseline tests fail, report the failures before continuing so new failures are not confused with pre-existing ones.

## Report

Report:

- Worktree path
- Branch name
- The base branch and commit the worktree started from, as the destination identity for later integration
- Setup command run, if any
- Baseline verification command and result
- Any pre-existing failures

## Red Flags

- Do not create a project-local worktree without ignore verification.
- Do not assume a directory when project instructions specify one.
- Do not skip baseline verification unless no relevant command exists.
- Do not delete a worktree or branch without explicit user authorization. An existing instruction covering the exact integration and cleanup actions satisfies confirmation, and an experiment the operator authorized covers removing the temporary worktree the parent created for it; do not ask again unless scope, ownership, or destructive risk has changed. Verify integration (or kept evidence, for an experiment) and ownership before cleanup, and preserve unrelated work.
