# AGENTS Profiles

This directory contains installable `AGENTS.md` profiles for Opencode.

All four profiles share the same baseline quality, delegation, verification, search, browser, handoff, worktree, and document-conversion rules. Interactive browser work routes to `chrome-devtools`. The `personal-*` profiles add the author's operator-writing style via the `ivan-writing` personal skill (loaded from `profiles/personal/skills/ivan-writing/`); the `shared*` profiles intentionally omit that voice layer. The `*-context-improved` profiles add strong explicit routing rules for the optional context-improved toolchain; the plain profiles use the baseline routing without those explicit assumptions.

## Why this exists

The repository root `AGENTS.md` governs work on this repository itself. The files in this directory are the profiles that get copied into `~/.config/opencode/AGENTS.md` by `scripts/install-profile.sh`.

These Opencode AGENTS profiles are not Cursor global Rules. Cursor default-Agent guidance lives in the Cursor asset root and is printed by the helper. Use `./scripts/cursor-assets.sh print-rules` and paste the output into Cursor Settings -> Rules.

## Profiles

### `shared.md`

Purpose: A portable default for other operators.

Use this when:

- you want the repo's shared operating rules
- you do not want the more opinionated writing-style defaults
- you want the safest starting point for another machine or team member

### `personal-default.md`

Purpose: The shared profile plus the author's operator-writing voice, driven by the personal `ivan-writing` skill.

Use this when:

- you want the agent to default to the author's operator-style writing profile
- you are comfortable with a more opinionated `AGENTS.md`
- you want a ready-made profile instead of writing a personal one from scratch

The `ivan-writing` skill is installed automatically by `scripts/install-profile.sh` when this profile is selected. It provides register-specific guidance (technical/operator, professional/application, casual/informal) and voice/cadence/word-choice rules.

### `shared-context-improved.md`

Purpose: The shared profile plus strong routing rules for the optional context-improved toolchain.

Use this when:

- you have enabled `profiles/optional/opencode.context-improved.json`
- you have also applied the matching `agent_hive.context-improved.json` overlay, either through `./scripts/enable-optional.sh context-improved` or automatically through `./scripts/install-profile.sh`
- `context-mode`, local `ast_grep`, and enabled `context7` are actually available in the running environment
- `cymbal` is available on `PATH` when you want agents to start unfamiliar-code navigation there
- you want agents to prefer the richer context and navigation workflow explicitly

### `personal-context-improved.md`

Purpose: The personal-default profile plus strong routing rules for the optional context-improved toolchain. Writing guidance is identical to personal-default.

Use this when:

- you want the agent to default to the operator-style writing profile, with the personal writing voice and an opt-in casual register (same as personal-default)
- you have enabled `profiles/optional/opencode.context-improved.json`
- you have also applied the matching `agent_hive.context-improved.json` overlay, either through `./scripts/enable-optional.sh context-improved` or automatically through `./scripts/install-profile.sh`
- you want the AGENTS policy to assume the context-improved tool bundle is present
- `cymbal` is available on `PATH` when you want agents to start unfamiliar-code navigation there

## Install selection

The installer uses `shared` by default.

By default, the installer replaces the selected `AGENTS.md` after backing it up. When the operator needs to keep an existing file and reconcile the new routing rules afterward, the merge flow should use `OPENCODE_AGENTS_MODE=skip` so the user's file stays in place.

Install the shared profile:

```bash
./scripts/install-profile.sh
```

Install the sanitized personal-default profile:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

Install the shared context-improved profile:

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
```

Install the personal context-improved profile:

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh
```

Some notes:

- the `*-context-improved` AGENTS profiles auto-apply `context-improved` during `./scripts/install-profile.sh`; use `./scripts/enable-optional.sh context-improved` when you want to add the bundle after a plain install
- the `*-context-improved` install commands require `jq`, `context-mode`, `uvx`, and `CONTEXT7_API_KEY` because the installer preflights and auto-applies the matching bundle
- the plain `shared` and `personal-default` profiles are the capability-safe defaults for the base install
- `skip` is the preservation path for an existing `AGENTS.md`; it leaves the file untouched so the agent can fold in the new guidance structurally afterward

The installer backs up any existing target config files before replacing them.
