# Cursor Assets

Prompt-level Cursor assets sourced from this repository and installed globally under `~/.cursor` by `scripts/cursor-assets.sh`.

## Source-to-target layout

| Source | Target | Notes |
|--------|--------|-------|
| `agents/*.md` | `~/.cursor/agents/*.md` | Cursor user-global subagents |
| `commands/*.md` | `~/.cursor/commands/*.md` | Cursor user-global commands |
| `skills/<name>/SKILL.md` | `~/.cursor/skills/<name>/SKILL.md` | Cursor user-global skills |
| `rules/default-agent.md` | Cursor Settings -> Rules (manual paste) | Cursor exposes user rules via the Settings UI, not a deployable file path |

The install target defaults to `${CURSOR_CONFIG_DIR:-$HOME/.cursor}`. Set `CURSOR_CONFIG_DIR` to a temp directory for validation or dry-run inspection.

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

## Opencode install isolation

`scripts/install-profile.sh` copies from `.apm/skills/`, `.apm/agents/`, and `.apm/prompts/*.prompt.md` into the Opencode config directory. It does not copy `.apm/cursor/**`. Cursor assets under `.apm/cursor/` do not appear in the Opencode install path and do not introduce new Opencode prompt-backed commands.
