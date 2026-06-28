# Cursor Setup

This repository ships a first-pass Cursor asset bundle for prompt-level behavior. It does not provide Agent Hive runtime parity in Cursor, and it does not install `oc-arkive`, Hive tools, Opencode commands, `opencode.json`, `agent_hive.json`, or an Opencode `AGENTS.md` profile.

Use this when you want Cursor to have similar reusable guidance, subagents, commands, and skills, while keeping execution inside Cursor's own feature set.

## What Cursor v1 Includes

The selected Cursor asset root contains:

- six subagents: `approach-advisor`, `code-reviewer`, `forager`, `plan-reviewer`, `scout`, and `simplicity-reviewer`
- five commands: `compact-summary`, `council-directive`, `council`, `implementation-brief`, and `interview`
- eleven core skills: `brainstorming`, `consolidate-test-suites`, `finishing-a-development-branch`, `humanizer`, `root-cause-finder`, `stop-slop`, `subagent-delegation`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, and `verification`
- one default-Agent Rules document at `rules/default-agent.md`

The default source root is `.apm/cursor`. If APM validation rejects unknown `.apm/cursor/**` content and a later task moves the bundle, the helper also supports the fallback root `cursor-assets/`. Do not hardcode only one root in local automation; let `scripts/cursor-assets.sh` select it.

## Why A Helper Installs The Assets

Current APM documentation shows project-local Cursor deployment under a repository `.cursor/` directory. It does not prove that pure `apm install -g` deploys agents, commands, skills, and Rules into global `~/.cursor`.

For v1, `scripts/cursor-assets.sh` is the installer boundary. It validates the selected asset root, copies supported assets into one or more target Cursor config directories, and prints the Rules text for manual paste. When install replaces existing Cursor files or directories, it writes backups under the helper's backup directory before replacement.

The target defaults to `~/.cursor`. For inspection, set `CURSOR_CONFIG_DIR` to a temporary directory. For dual installs, set `CURSOR_CONFIG_DIRS` to a semicolon-separated list.

## Prerequisites

- Run commands from this repository root.
- `python3` must be available on `PATH`.
- `scripts/cursor-assets.sh` must exist and be executable.
- The default target is `${HOME}/.cursor`.
- Set `CURSOR_CONFIG_DIR=/path/to/cursor-config` to validate, dry-run, or install into one custom target.
- Set `CURSOR_CONFIG_DIRS="/path/one;/path/two"` to install into multiple Cursor config roots.

## Windows Cursor With WSL Projects

Windows Cursor can use a different global asset root when the active project is opened through WSL. Installing only into the Windows config directory can leave WSL projects without the file-based agents, commands, and skills; installing only into WSL can leave normal Windows projects without them.

When Windows Cursor is used for both Windows and WSL workspaces, install into both config roots:

```bash
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install --dry-run
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install
```

Replace `<WindowsUser>` with the Windows account name. The first target is the WSL global Cursor config. The second target is the Windows global Cursor config as seen from WSL. If running from Git Bash on Windows, use the Git Bash path for the Windows config instead.

## Install Flow

Validate the asset bundle first:

```bash
./scripts/cursor-assets.sh validate
```

Inspect the copy plan against a temporary target:

```bash
CURSOR_CONFIG_DIR=/path/to/temp ./scripts/cursor-assets.sh install --dry-run
```

Install into the target Cursor config directory:

```bash
./scripts/cursor-assets.sh install
```

Install into two target Cursor config directories:

```bash
CURSOR_CONFIG_DIRS="/path/to/first;/path/to/second" ./scripts/cursor-assets.sh install
```

Print the default-Agent Rules text:

```bash
./scripts/cursor-assets.sh print-rules
```

Paste that output into Cursor Settings -> Rules. The helper does not write undocumented Cursor settings files.

## What Is Deliberately Excluded

Cursor v1 excludes the Agent Hive runtime command and tool surface because those pieces belong to Opencode plus `oc-arkive`, not Cursor prompt assets.

Excluded examples include:

- Hive lifecycle commands such as plan approval, task sync, worktree start, merge, and feature completion
- Hive MCP/tool calls and OpenCode-only tool syntax
- `opencode.json`, `agent_hive.json`, Opencode `AGENTS.md`, and optional Opencode MCP/LSP snippets
- the `oc-arkive` plugin and the VS Code companion extension

The Cursor assets can describe workflows and review expectations, but they cannot create Agent Hive features, update Hive task state, call Hive tools, or guarantee the same runtime behavior as Opencode.

## Verify The Installed Layout

After installing, check every target config directory. If you used a custom target, inspect `${CURSOR_CONFIG_DIR:-$HOME/.cursor}` instead of the literal `~/.cursor` examples below. If you used `CURSOR_CONFIG_DIRS`, inspect each semicolon-separated target.

```bash
cursor_target="${CURSOR_CONFIG_DIR:-$HOME/.cursor}"
ls "$cursor_target/agents"
ls "$cursor_target/commands"
ls "$cursor_target/skills"
```

Expected high-level layout:

```text
~/.cursor/agents/approach-advisor.md
~/.cursor/agents/code-reviewer.md
~/.cursor/agents/forager.md
~/.cursor/agents/plan-reviewer.md
~/.cursor/agents/scout.md
~/.cursor/agents/simplicity-reviewer.md
~/.cursor/commands/compact-summary.md
~/.cursor/commands/council-directive.md
~/.cursor/commands/council.md
~/.cursor/commands/implementation-brief.md
~/.cursor/commands/interview.md
~/.cursor/skills/<skill-name>/SKILL.md
```

For a non-destructive verification run, install into a temp directory and inspect that directory instead:

```bash
CURSOR_CONFIG_DIR=/path/to/temp ./scripts/cursor-assets.sh install
```

Then inspect `/path/to/temp/agents`, `/path/to/temp/commands`, and `/path/to/temp/skills`.

For dual-target verification, install into two temp directories:

```bash
one="$(mktemp -d)"
two="$(mktemp -d)"
CURSOR_CONFIG_DIRS="$one;$two" ./scripts/cursor-assets.sh install
```

Then inspect both `$one` and `$two`.

## Smoke Testing

No live Cursor behavioral smoke test is required for v1. The acceptance boundary is static validation, installed file layout, and manual Rules paste into Cursor Settings -> Rules.
