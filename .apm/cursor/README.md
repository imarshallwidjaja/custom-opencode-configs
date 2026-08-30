# Cursor Assets

Prompt-level Cursor assets sourced from this repository and installed globally under Cursor config directories by `scripts/cursor-assets.sh`. The default parent Agent uses Hive-Builder-like delegation-first orchestration with Cursor-native named subagents; it is not Agent Hive runtime parity and has no Hive tools, state, task DAG, board, or worktree lifecycle.

Delegation is a strong prompt policy, but Cursor routing is heuristic and not runtime-guaranteed. The bounded direct-work exception covers coordination, setup, trivial conversation, and at most one bounded read, one bounded write or patch, and one cheap focused check. Separate context does not isolate files in a shared checkout. Overlapping writers require explicit worktrees or isolated project copies; otherwise children must own disjoint paths or run serially.

## Inventory

- six subagents: `approach-advisor`, `code-reviewer`, `forager`, `plan-reviewer`, `scout`, `simplicity-reviewer`
- eight installed commands: seven Cursor-specific commands (`compact-summary`, `council-directive`, `council`, `implementation-brief`, `interview`, `interview-drill-down`, `planning-prompt`) plus the shared canonical `reflect`
- ten managed Cursor skills installed into Cursor `skills/`: `agents-md-mastery`, `brainstorming`, `consolidate-test-suites`, `finishing-a-development-branch`, `root-cause-finder`, `subagent-delegation`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `verification`
- twelve shared canonical skills consumed from `.apm/skills/` and installed into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`: `cymbal`, `drawio-skill`, `frontend-slides`, `hard-cut`, `humanizer`, `react-best-practices`, `resume-tailoring`, `stop-design-slop`, `stop-slop`, `use-railway`, `web-design-guidelines`, `writing-for-humans`
- optional personal skill `ivan-writing` installed into the agents dir when `CURSOR_INSTALL_IVAN_WRITING=1` is set

`use-railway` needs the Railway CLI and Railway auth; without them the skill is unused. `drawio-skill` needs `uv` and the draw.io desktop CLI; Graphviz is optional. `frontend-slides` needs `uv` for PPTX conversion and Node.js for PDF export or Vercel deploy.

## Source-to-target layout

| Source | Target | Notes |
|--------|--------|-------|
| `agents/*.md` | `<cursor-config>/agents/*.md` | Cursor user-global subagents |
| `.apm/cursor/commands/*.md` | `<cursor-config>/commands/*.md` | Seven genuinely Cursor-specific user-global commands |
| `.apm/prompts/reflect.prompt.md` | `<cursor-config>/commands/reflect.md` | Shared `/reflect` policy, installed byte-for-byte by the helper |
| `skills/<name>/` | `<cursor-config>/skills/<name>/` | Cursor-only and Hive-overlay skills; require `SKILL.md` and may include `references/` and `scripts/` |
| `.apm/skills/<name>/` | `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}/<name>/` | Shared canonical skills used by Cursor and OpenCode. The installer also backs up and removes stale copies of those names from each Cursor target `skills/` directory |
| `rules/default-agent.md` | Cursor Customize -> Rules -> User Rules (manual paste) | Cursor exposes user rules via the Customize UI, not a deployable file path |
| `vendor/oc-arkive/engineering-judgment/engineering-judgment.md` | Cursor Customize -> Rules -> User Rules (composed by `print-rules`) | Provenance-pinned generated snapshot; it is validated but not copied by `install` |

The install target defaults to `${CURSOR_CONFIG_DIR:-$HOME/.cursor}`. Set `CURSOR_CONFIG_DIR` to one custom target, or set `CURSOR_CONFIG_DIRS` to a semicolon-separated target list for dual installs. Shared canonical skills default to `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`; override `AGENTS_SKILLS_DIR` for tests or isolated installs so a real `$HOME` is not mutated.

`.apm/prompts/reflect.prompt.md` is the only tracked `/reflect` command source. Validation rejects `.apm/cursor/commands/reflect.md` as a stale duplicate. APM routes the canonical prompt to project-local Opencode and Cursor command targets; it may normalize frontmatter or newlines, but both targets retain the same command metadata and body semantics.

Windows Cursor can read different global asset roots depending on whether the active workspace is a normal Windows folder or a WSL folder. For Windows Cursor used with WSL projects, install into both roots, for example:

```bash
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install
```

## Subagent readonly choices

The parent coordinates non-trivial work instead of acting as the default implementation worker. It routes ordinary bounded implementation, bug fixes, refactoring, tests, and documentation to `forager`, read-only discovery to `scout`, uncertain or costly-to-reverse direction to `approach-advisor`, plan readiness to `plan-reviewer` only when a plan is requested, completed-change correctness review to `code-reviewer`, and final proportional cleanup to `simplicity-reviewer`. Cursor children share the checkout unless an isolated project copy or worktree is explicitly used, so parent handoffs assign non-overlapping path ownership and carry critical instructions that User Rules may not propagate to children.

The Cursor subagent files use `model: inherit` so they follow the caller's selected model. Read-only roles set `readonly: true`: `scout`, `plan-reviewer`, `code-reviewer`, `simplicity-reviewer`, and `approach-advisor`.

`forager` sets `readonly: false` explicitly because it is the write-capable implementation role. Keeping the field explicit is safer than relying on a default when these assets are copied between machines or Cursor versions.

## Why a helper, not pure APM

APM (Microsoft Agent Package Manager) deploys primitives to **project-local** harness directories (`.cursor/` in the project root), not to the user-global `~/.cursor/` directory. Current APM docs do not show `apm install -g` deploying global agents, commands, and skills into `~/.cursor`.

The thin helper `scripts/cursor-assets.sh` handles validation, temp/global copy, and manual Rules printing because no reliable pure-APM path exists for user-global Cursor assets. The printed Rules append the vendored Engineering Judgment snapshot; when its provenance hash changes, regenerate and repaste the complete Rules output. User Rules apply to Agent Chat, not Inline Edit, and project `.cursor/rules/*.mdc` remains a separate opt-in mechanism rather than an automatic install target.

The current npm `oc-arkive@latest` is 2.3.5 and includes Engineering Judgment. OpenCode receives Engineering Judgment from the installed plugin. Cursor continues to use the provenance-pinned vendored snapshot because Cursor cannot load the plugin prompt directly. Provenance `packageVersion` is metadata from the selected source checkout, not evidence of npm publication. Maintainer sync requires Git, Python 3, and a local Agent Hive checkout containing the selected ref.

Hive-overlapping skill packaging is in README.md. Maintainer sync for the four Hive-pinned Cursor skills is in CURSOR.md.

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

The twelve shared canonical skills (`cymbal`, `drawio-skill`, `frontend-slides`, `hard-cut`, `humanizer`, `react-best-practices`, `resume-tailoring`, `stop-design-slop`, `stop-slop`, `use-railway`, `web-design-guidelines`, `writing-for-humans`) are consumed from `.apm/skills/` and installed into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`, not duplicated under `.apm/cursor/skills/` or copied into Cursor `skills/`. OpenCode prefers `~/.config/opencode/skills` over `~/.agents/skills` when both exist, so a leftover shared copy in a harness skills directory would keep serving the stale tree. Cursor and OpenCode also scan `~/.claude/skills`, so shared skills must not be left there either.

`drawio-skill` needs `uv` and the draw.io desktop CLI; Graphviz is optional for auto-layout. `frontend-slides` needs `uv` for PPTX conversion and Node.js for PDF export or Vercel deploy. Without those tools the skills remain unused.

The personal `ivan-writing` skill is installed from `profiles/personal/skills/ivan-writing/` into the agents dir only when `CURSOR_INSTALL_IVAN_WRITING=1` is set. This is an opt-in because the skill contains the author's personal voice preferences. Only unset/empty and exact `1` are accepted; other values (0, false, 2) fail before any target mutation.

When opt-in installs `ivan-writing`, the helper writes a marker file `ivan-writing/.cursor-managed` inside the agents-dir skill directory and backs up and removes a leftover Cursor `skills/ivan-writing`. On later opt-out, the agents-dir skill is backed up and removed only when that marker exists, and a Cursor `skills/ivan-writing` that still has `.cursor-managed` is also backed up and removed. An unowned `ivan-writing` directory (no marker) is preserved and not modified.

## Opencode install isolation

`scripts/install-profile.sh` copies OpenCode-local skills from `.apm/skills/` into the Opencode config `skills/` directory, upserts the twelve shared canonical skills into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`, and copies `.apm/agents/` and `.apm/prompts/*.prompt.md` into the Opencode config directory. It does not copy `.apm/cursor/**`, including the Cursor-specific `agents-md-mastery` adaptation. Opencode prompt-backed commands come only from `.apm/prompts/`, currently `interview-drill-down`, `planning-prompt`, and `reflect`.

For personal profiles (`personal-default`, `personal-context-improved`), `scripts/install-profile.sh` copies from `profiles/personal/skills/` into the agents dir, not into the OpenCode `skills/` directory.
