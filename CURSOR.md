# Cursor Setup

This repository ships a first-pass Cursor asset bundle for prompt-level behavior. It does not provide Agent Hive runtime parity in Cursor, and it does not install `oc-arkive`, Hive tools, Opencode commands, `opencode.json`, `agent_hive.json`, or an Opencode `AGENTS.md` profile.

Use this when you want Cursor to have similar reusable guidance, subagents, commands, and skills, while keeping execution inside Cursor's own feature set.

## What Cursor v1 Includes

The selected Cursor asset root contains:

- six subagents: `approach-advisor`, `code-reviewer`, `forager`, `plan-reviewer`, `scout`, and `simplicity-reviewer`
- eight installed commands: seven Cursor-specific commands (`compact-summary`, `council-directive`, `council`, `implementation-brief`, `interview`, `interview-drill-down`, `planning-prompt`) plus the shared canonical `reflect`
- eleven Cursor-specific skills: `agents-md-mastery`, `brainstorming`, `consolidate-test-suites`, `finishing-a-development-branch`, `root-cause-finder`, `subagent-delegation`, `systematic-debugging`, `test-driven-development`, `use-railway`, `using-git-worktrees`, and `verification`
- six canonical skills consumed from `.apm/skills/`: `drawio-skill`, `frontend-slides`, `humanizer`, `stop-design-slop`, `stop-slop`, and `writing-for-humans`
- optional personal skill `ivan-writing` installed when `CURSOR_INSTALL_IVAN_WRITING=1` is set
- one default-Agent Rules document at `rules/default-agent.md`

The default Cursor-specific source root is `.apm/cursor`. If APM validation rejects unknown `.apm/cursor/**` content and a later task moves the bundle, the helper also supports the fallback root `cursor-assets/`. The shared `/reflect` source remains `.apm/prompts/reflect.prompt.md` in either layout. Do not hardcode only one Cursor-specific root in local automation; let `scripts/cursor-assets.sh` select it.

## Why A Helper Installs The Assets

Current APM documentation shows project-local Cursor deployment under a repository `.cursor/` directory. It does not prove that pure `apm install -g` deploys agents, commands, skills, and Rules into global `~/.cursor`.

For v1, `scripts/cursor-assets.sh` is the installer boundary. It validates the selected Cursor-specific asset root, rejects a competing `.apm/cursor/commands/reflect.md`, copies `/reflect` from `.apm/prompts/reflect.prompt.md`, installs the other supported assets into one or more target Cursor config directories, and prints the Rules text for manual paste. When install replaces existing Cursor files or directories, it writes backups under the helper's backup directory before replacement.

APM also routes `.apm/prompts/reflect.prompt.md` to project-local Opencode and Cursor command targets. APM may normalize frontmatter or newlines, so semantic metadata/body parity is the contract there; helper installs remain byte-identical to the canonical source.

The target defaults to `~/.cursor`. For inspection, set `CURSOR_CONFIG_DIR` to a temporary directory. For dual installs, set `CURSOR_CONFIG_DIRS` to a semicolon-separated list.

## Prerequisites

- Run commands from this repository root.
- `python3` must be available on `PATH`.
- `scripts/cursor-assets.sh` must exist and be executable.
- The default target is `${HOME}/.cursor`.
- Set `CURSOR_CONFIG_DIR=/path/to/cursor-config` to validate, dry-run, or install into one custom target.
- Set `CURSOR_CONFIG_DIRS="/path/one;/path/two"` to install into multiple Cursor config roots.
- `railway` CLI plus Railway auth when you want the packaged `use-railway` skill to operate Railway infrastructure.
- `uv` plus the draw.io desktop CLI when you want the packaged `drawio-skill` to generate or export diagrams. Graphviz (`dot`) is optional for auto-layout.
- Node.js when you want `frontend-slides` PDF export or Vercel deploy helpers; `uv` when converting PPTX.
- Set `CURSOR_INSTALL_IVAN_WRITING=1` to also install the personal `ivan-writing` skill from `profiles/personal/skills/ivan-writing/`.
- Accepted values: unset/empty (opt-out, no personal skill) and exact `1` (opt-in). Any other value (0, false, 2, etc.) fails before install or dry-run starts.
- When opt-in installs `ivan-writing`, the helper writes a hidden marker file `skills/ivan-writing/.cursor-managed` inside the installed skill directory.
- On later opt-out (CURSOR_INSTALL_IVAN_WRITING unset), the helper backs up and removes `skills/ivan-writing` only when the in-directory `.cursor-managed` marker exists. If no marker exists, an existing `ivan-writing` directory is left untouched. A deleted-then-recreated user-owned directory is preserved.
- Dry-run accurately describes only the expected managed removal when the in-directory marker exists, and "preserving" when it does not.

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
- `opencode.json`, `agent_hive.json`, Opencode `AGENTS.md`, and optional Opencode MCP snippets
- the `oc-arkive` plugin and the VS Code companion extension

The Cursor assets can describe workflows and review expectations, but they cannot create Agent Hive features, update Hive task state, call Hive tools, or guarantee the same runtime behavior as Opencode.

The shared `/reflect` command uses only evidence and targets available to the current harness. In Cursor, it waits for operator approval before editing accessible instruction files; when a scratchpad or global target is unavailable, it returns the approved exact change and manual destination without claiming to apply it. Cursor User Rules uses the explicit `cursor-user-rules:manual` target: the current Rules text must be supplied or visible for conflict analysis, and an approved change is returned with exact manual-paste instructions rather than a claim that Cursor Settings was read or edited.

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
~/.cursor/commands/interview-drill-down.md
~/.cursor/commands/planning-prompt.md
~/.cursor/commands/reflect.md
~/.cursor/skills/agents-md-mastery/SKILL.md
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

## Integration Tests

Run the install contract tests from the repository root:

```bash
bash tests/test-install-contracts.sh
```

The test builds isolated repository fixtures in a temp directory — it never moves, deletes, or mutates repository source files. The EXIT trap only cleans up temp fixtures.
