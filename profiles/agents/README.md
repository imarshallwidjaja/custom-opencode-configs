# AGENTS Profiles

This directory contains installable `AGENTS.md` profiles for Opencode.

## Why this exists

The repository root `AGENTS.md` governs work on this repository itself. The files in this directory are the profiles that get copied into `~/.config/opencode/AGENTS.md` by `scripts/install-profile.sh`.

## Profiles

### `shared.md`

Purpose: A portable default for other operators.

Use this when:

- you want the repo's shared operating rules
- you do not want the author's more opinionated writing defaults
- you want the safest starting point for another machine or team member

### `personal-default.md`

Purpose: The shared profile plus a sanitized version of the author's preferred writing and operating voice.

Use this when:

- you want the agent to default to the repo author's style
- you are comfortable with a more opinionated `AGENTS.md`
- you want a ready-made profile instead of writing a personal one from scratch

### `shared-context-improved.md`

Purpose: The shared profile plus strong routing rules for the optional context-improved toolchain.

Use this when:

- you have enabled `profiles/optional/opencode.context-improved.json`
- `context-mode`, local `ast_grep`, and enabled `context7` are actually available in the running environment
- you want agents to prefer the richer context and navigation workflow explicitly

### `personal-context-improved.md`

Purpose: The personal-default profile plus strong routing rules for the optional context-improved toolchain.

Use this when:

- you want the agent to default to the repo author's style
- you have enabled `profiles/optional/opencode.context-improved.json`
- you want the AGENTS policy to assume the context-improved tool bundle is present

## Install selection

The installer uses `shared` by default.

The installer always replaces the selected `AGENTS.md` after backing it up. When the operator needs to keep an existing file and reconcile the new routing rules afterward, the merge flow should use `OPENCODE_AGENTS_MODE=skip` so the user's file stays in place.

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
OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
```

Install the personal context-improved profile:

```bash
OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh
```

Some notes:

- the `*-context-improved` AGENTS profiles should be paired with `./scripts/enable-optional.sh context-improved`
- the plain `shared` and `personal-default` profiles are the capability-safe defaults for the base install
- `skip` is the preservation path for an existing `AGENTS.md`; it leaves the file untouched so the agent can fold in the new guidance structurally afterward

The installer backs up any existing target config files before replacing them.
