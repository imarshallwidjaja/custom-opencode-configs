# Opencode Config Repository

Use this repository as the source of truth for the portable Opencode profile.

## Scope

- Keep `opencode.json` and `agent_hive.json` portable.
- Keep APM-installable markdown assets under `.apm/`.
- Exclude secrets, absolute home-directory paths, local proxy URLs, and personal workflows from the base profile.

## Configuration Rules

- Prefer remote plugin references such as `opencode-hive` over local build paths.
- Prefer environment variables for API keys and other machine-specific values.
- Keep the default profile limited to remote-only models so it works without local provider shims.
- Add optional providers, MCPs, and LSPs only when their prerequisites are documented in `README.md`.

## Content Rules

- Shared skills, command prompts, and agents belong in `.apm/`.
- Personal or domain-specific automation should stay out of the base package unless it is clearly marked optional.
- When migrating content from another tool-specific layout, normalize it to the current Opencode directory conventions.

## Verification

- Validate JSON files after edits.
- Validate the APM package layout before claiming the profile is ready.
- Test the install flow against a temporary `OPENCODE_CONFIG_DIR` when changing packaging behavior.
