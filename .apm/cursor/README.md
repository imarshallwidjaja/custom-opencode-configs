# Cursor Assets

Prompt-level Cursor assets sourced from this repository and installed globally under Cursor config directories by `scripts/cursor-assets.sh`.

## Inventory

- six subagents: `approach-advisor`, `code-reviewer`, `forager`, `plan-reviewer`, `scout`, `simplicity-reviewer`
- eight installed commands: seven Cursor-specific commands (`compact-summary`, `council-directive`, `council`, `implementation-brief`, `interview`, `interview-drill-down`, `planning-prompt`) plus the shared canonical `reflect`
- eleven Cursor-specific skills: `agents-md-mastery`, `brainstorming`, `consolidate-test-suites`, `finishing-a-development-branch`, `root-cause-finder`, `subagent-delegation`, `systematic-debugging`, `test-driven-development`, `use-railway`, `using-git-worktrees`, `verification`
- six canonical skills consumed from `.apm/skills/`: `drawio-skill`, `frontend-slides`, `humanizer`, `stop-design-slop`, `stop-slop`, `writing-for-humans`
- optional personal skill `ivan-writing` installed when `CURSOR_INSTALL_IVAN_WRITING=1` is set

`use-railway` needs the Railway CLI and Railway auth; without them the skill is unused. `drawio-skill` needs `uv` and the draw.io desktop CLI; Graphviz is optional. `frontend-slides` needs `uv` for PPTX conversion and Node.js for PDF export or Vercel deploy.

## Source-to-target layout

| Source | Target | Notes |
|--------|--------|-------|
| `agents/*.md` | `<cursor-config>/agents/*.md` | Cursor user-global subagents |
| `.apm/cursor/commands/*.md` | `<cursor-config>/commands/*.md` | Seven genuinely Cursor-specific user-global commands |
| `.apm/prompts/reflect.prompt.md` | `<cursor-config>/commands/reflect.md` | Shared `/reflect` policy, installed byte-for-byte by the helper |
| `skills/<name>/` | `<cursor-config>/skills/<name>/` | Cursor user-global skills; Cursor-specific skills require `SKILL.md` and may include `references/` and `scripts/`. Canonical skills copied from `.apm/skills/` may also include packaged files such as `viewport-base.css`, `bin/`, `data/`, `styles/`, `assets/`, and `examples/` |
| `rules/default-agent.md` | Cursor Settings -> Rules (manual paste) | Cursor exposes user rules via the Settings UI, not a deployable file path |

The install target defaults to `${CURSOR_CONFIG_DIR:-$HOME/.cursor}`. Set `CURSOR_CONFIG_DIR` to one custom target, or set `CURSOR_CONFIG_DIRS` to a semicolon-separated target list for dual installs.

`.apm/prompts/reflect.prompt.md` is the only tracked `/reflect` command source. Validation rejects `.apm/cursor/commands/reflect.md` as a stale duplicate. APM routes the canonical prompt to project-local Opencode and Cursor command targets; it may normalize frontmatter or newlines, but both targets retain the same command metadata and body semantics.

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

The currently resolved APM CLI accepts this package and ignores `.apm/cursor/**` during normal primitive routing. If a future APM release rejects that directory, move the entire Cursor source bundle to the supported fallback path (`cursor-assets/` at the repository root) and update the helper and docs together.

## `type: hybrid` in `apm.yml`

The currently resolved APM CLI accepts the existing `type: hybrid` manifest and routes the canonical `.apm/prompts/` and `.apm/skills/` primitives to Opencode and Cursor targets. Keep the field unchanged unless a later APM schema requires a different package type.

For package-layout verification, work from a disposable copy because `apm install` writes a lockfile and target directories, then run:

```bash
uvx --from apm-cli apm install --target opencode,cursor
```

## Canonical shared sourcing

Other Cursor commands continue to come from `.apm/cursor/commands/`.

`drawio-skill`, `frontend-slides`, `humanizer`, `stop-design-slop`, `stop-slop`, and `writing-for-humans` are consumed from `.apm/skills/` (the canonical source shared with Opencode), not duplicated under `.apm/cursor/skills/`. The Cursor installer copies them from the canonical source.

`drawio-skill` needs `uv` and the draw.io desktop CLI; Graphviz is optional for auto-layout. `frontend-slides` needs `uv` for PPTX conversion and Node.js for PDF export or Vercel deploy. Without those tools the skills remain unused.

The personal `ivan-writing` skill is installed from `profiles/personal/skills/ivan-writing/` only when `CURSOR_INSTALL_IVAN_WRITING=1` is set. This is an opt-in because the skill contains the author's personal voice preferences. Only unset/empty and exact `1` are accepted; other values (0, false, 2) fail before any target mutation.

When opt-in installs `ivan-writing`, the helper writes a marker file `skills/ivan-writing/.cursor-managed` inside the installed skill directory. On later opt-out, the skill directory is backed up and removed only when that marker exists. An unowned `ivan-writing` directory (no marker) is preserved and not modified.

## Opencode install isolation

`scripts/install-profile.sh` copies from `.apm/skills/`, `.apm/agents/`, and `.apm/prompts/*.prompt.md` into the Opencode config directory. It does not copy `.apm/cursor/**`, including the Cursor-specific `agents-md-mastery` adaptation. Opencode prompt-backed commands come only from `.apm/prompts/`, currently `interview-drill-down`, `planning-prompt`, and `reflect`.

For personal profiles (`personal-default`, `personal-context-improved`), `scripts/install-profile.sh` also copies from `profiles/personal/skills/` into the Opencode config directory.
