---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from the current checkout; creates a git worktree with safe directory selection and baseline verification.
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces that share the same repository. Use them when feature work, risky fixes, or parallel branches should not disturb the current checkout.

## Directory Selection

Use this priority order:

1. Existing `.worktrees/` directory in the project.
2. Existing `worktrees/` directory in the project.
3. A project instruction file that specifies a worktree directory.
4. Ask the user to choose between a project-local ignored directory and a global location such as `~/.local/share/agent-worktrees/<project-name>/`.

If both `.worktrees/` and `worktrees/` exist, prefer `.worktrees/`.

## Safety Verification

For project-local directories, verify the directory is ignored before creating a worktree:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If the chosen project-local directory is not ignored, fix that hygiene issue before creating the worktree.

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

For a global location, use a path like:

```bash
path="$HOME/.local/share/agent-worktrees/$project/$branch_name"
```

## Baseline Setup

Run project-appropriate setup and checks:

```bash
if [ -f package.json ]; then npm install; fi
if [ -f Cargo.toml ]; then cargo build; fi
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi
if [ -f go.mod ]; then go mod download; fi
```

Then run the nearest baseline test command, such as `npm test`, `cargo test`, `pytest`, or `go test ./...`.

If baseline tests fail, report the failures before continuing so new failures are not confused with pre-existing ones.

## Report

Report:

- Worktree path
- Branch name
- Setup command run, if any
- Baseline verification command and result
- Any pre-existing failures

## Red Flags

- Do not create a project-local worktree without ignore verification.
- Do not assume a directory when project instructions specify one.
- Do not skip baseline verification unless no relevant command exists.
- Do not delete a worktree or branch without explicit user confirmation.
