# Cursor Assets

Prompt-level Cursor assets sourced from this repository and installed globally under Cursor config directories by `scripts/cursor-assets.sh`.

## Inventory

- six subagents: `approach-advisor`, `code-reviewer`, `forager`, `plan-reviewer`, `scout`, `simplicity-reviewer`
- seven commands: `compact-summary`, `council-directive`, `council`, `implementation-brief`, `interview`, `interview-drill-down`, `planning-prompt`
- ten Cursor-specific skills: `brainstorming`, `consolidate-test-suites`, `finishing-a-development-branch`, `root-cause-finder`, `subagent-delegation`, `systematic-debugging`, `test-driven-development`, `use-railway`, `using-git-worktrees`, `verification`
- two canonical skills consumed from `.apm/skills/`: `humanizer` and `stop-slop`
- optional personal skill `ivan-writing` installed when `CURSOR_INSTALL_IVAN_WRITING=1` is set

`use-railway` needs the Railway CLI and Railway auth; without them the skill is unused.

## Source-to-target layout

| Source | Target | Notes |
|--------|--------|-------|
| `agents/*.md` | `<cursor-config>/agents/*.md` | Cursor user-global subagents |
| `commands/*.md` | `<cursor-config>/commands/*.md` | Cursor user-global commands |
| `skills/<name>/` | `<cursor-config>/skills/<name>/` | Cursor user-global skills; each skill requires `SKILL.md` and may include `references/` and `scripts/` |
| `rules/default-agent.md` | Cursor Settings -> Rules (manual paste) | Cursor exposes user rules via the Settings UI, not a deployable file path |

The install target defaults to `${CURSOR_CONFIG_DIR:-$HOME/.cursor}`. Set `CURSOR_CONFIG_DIR` to one custom target, or set `CURSOR_CONFIG_DIRS` to a semicolon-separated target list for dual installs.

Windows Cursor can read different global asset roots depending on whether the active workspace is a normal Windows folder or a WSL folder. For Windows Cursor used with WSL projects, install into both roots, for example:

```bash
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install
```

## Subagent readonly choices

The Cursor subagent files use `model: inherit` so they follow the caller's selected model. Read-only roles set `readonly: true`: `scout`, `plan-reviewer`, `code-reviewer`, `simplicity-reviewer`, and `approach-advisor`.

`forager` sets `readonly: false` explicitly because it is the write-capable implementation role. Keeping the field explicit is safer than relying on a default when these assets are copied between machines or Cursor versions.

## Why a helper, not pure APM

APM (Microsoft Agent Package Manager) deploys primitives to **project-local** harness directories (`.cursor/` in the project root), not to the user-global `~/.cursor/` directory. Current APM docs do not show `apm install -g` deploying global agents, commands, and skills into `~/.cursor`.

The thin helper `scripts/cursor-assets.sh` handles validation, temp/global copy, and manual Rules printing because no reliable pure-APM path exists for user-global Cursor assets.

## APM layout note

APM organizes package primitives by type under `.apm/` (`.apm/skills/`, `.apm/agents/`, `.apm/prompts/`, `.apm/instructions/`), not by target harness. `.apm/cursor/` is a non-standard directory that APM does not route. It is used here as a source bundle for the helper, not as an APM primitive path.

If APM validation rejects unknown `.apm/cursor/**` content rather than ignoring it, move the entire Cursor source bundle to a neutral top-level path (`cursor-assets/` at the repository root) and update the helper and docs to match. APM CLI was not available during initial implementation to confirm whether APM rejects or ignores this directory.

## `type: hybrid` in `apm.yml`

The `type: hybrid` field in `apm.yml` was left unchanged. External APM docs indicate `type` is advisory, but the APM CLI was not available to confirm whether `hybrid` is correct or incorrect for this package layout. Changing it without CLI validation risks breaking APM metadata expectations. If a later APM CLI check confirms the field is advisory and `hybrid` is semantically wrong for an `.apm/` primitive package, correct it in the same change that adds APM CLI validation evidence.

## Canonical skill sourcing

`humanizer` and `stop-slop` are consumed from `.apm/skills/` (the canonical source shared with Opencode), not duplicated under `.apm/cursor/skills/`. The Cursor installer copies them from the canonical source.

The personal `ivan-writing` skill is installed from `profiles/personal/skills/ivan-writing/` only when `CURSOR_INSTALL_IVAN_WRITING=1` is set. This is an opt-in because the skill contains the author's personal voice preferences. Only unset/empty and exact `1` are accepted; other values (0, false, 2) fail before any target mutation.

When opt-in installs `ivan-writing`, the helper writes a marker file `skills/ivan-writing/.cursor-managed` inside the installed skill directory. On later opt-out, the skill directory is backed up and removed only when that marker exists. An unowned `ivan-writing` directory (no marker) is preserved and not modified.

## Opencode install isolation

`scripts/install-profile.sh` copies from `.apm/skills/`, `.apm/agents/`, and `.apm/prompts/*.prompt.md` into the Opencode config directory. It does not copy `.apm/cursor/**`. Cursor assets under `.apm/cursor/` do not appear in the Opencode install path. Opencode prompt-backed commands come only from `.apm/prompts/`, currently `interview-drill-down` and `planning-prompt`.

For personal profiles (`personal-default`, `personal-context-improved`), `scripts/install-profile.sh` also copies from `profiles/personal/skills/` into the Opencode config directory.
