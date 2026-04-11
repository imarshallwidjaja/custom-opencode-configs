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

## Install selection

The installer uses `shared` by default.

Install the shared profile:

```bash
./scripts/install-profile.sh
```

Install the sanitized personal-default profile:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

The installer backs up any existing target config files before replacing them.
