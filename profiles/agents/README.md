# AGENTS Profiles

This directory contains installable `AGENTS.md` profiles for Opencode.

The accompanying config targets `oc-arkive` v3.0.0 and requires OpenCode >= 1.18.30. Check `opencode --version` and upgrade an older host before updating the plugin or profile. Research MCPs are operator-configured and work independently of skill availability; Hive v3 does not bundle an `ast-grep` skill, and these profiles route directly to the MCP tools.

All four profiles share the same baseline quality, delegation, verification, search, browser, handoff, worktree, and document-conversion rules. Interactive browser work routes to `chrome-devtools`. Their `## Prose policy` section references `writing-policy` for prose routing and delegated propagation, including each child's own skill loads and the task's required output format. `writing-for-humans` owns drafting, the finish pass, and durable naming. `stop-slop` and `humanizer` load conditionally for matching rewrite problems. The three document-focused Hive roles auto-load `writing-policy` and `writing-for-humans`; `adversarial-documentation-reviewer` also retains `adversarial-review`.

The `personal-*` profiles install Ivan's voice skill and load `ivan-writing` only for prose published, submitted, or sent as Ivan; internal worker reports stay neutral unless requested. PR and review drafts require explicit operator selection of personal voice under `pr-writing`. The `shared*` profiles omit that voice layer. The `*-context-improved` profiles add strong explicit routing rules for the optional context-improved toolchain; the plain profiles use the baseline routing without those explicit assumptions.

These profile references do not establish which skill copy a running Opencode session loads. The installer still supplies shared writing skills under `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}` as described in the root README; retiring those sources or resolving local overrides requires separate work.

All four profiles also share `Request And Skill Precedence`: explicit user intent overrides skill defaults within higher-priority instructions, tool permissions, and project requirements. Clear implementation requests proceed, advice-only scope stays read-only, skill-driven pauses cite the instruction, and verification stops after acceptance and required gates absent new changes, failures, or concrete unresolved risk. Preserve this section when merging a profile into an existing `AGENTS.md`.

## Why this exists

The repository root `AGENTS.md` governs work on this repository itself. The files in this directory are the profiles that get copied into `~/.config/opencode/AGENTS.md` by `scripts/install-profile.sh`; the base JSON payloads installed alongside them live under `profiles/base/`.

Running `./scripts/install-profile.sh` with no arguments previews without changes or hooks. Use `--apply` to install immediately, or `--help` for usage.

These Opencode AGENTS profiles are not Cursor global Rules. Cursor default-Agent guidance lives in the Cursor asset root and is printed by the helper. Use `./scripts/cursor-assets.sh print-rules` and paste the output into Cursor Customize -> Rules -> User Rules.

## Profiles

### `shared.md`

Purpose: A portable default for other operators.

Use this when:

- you want the repo's shared operating rules
- you do not want the more opinionated writing-style defaults
- you want the safest starting point for another machine or team member

### `personal-default.md`

Purpose: The shared profile plus Ivan's voice skill. That voice is selected only for prose published, submitted, or sent as Ivan; internal worker reports stay neutral unless requested. PR and review drafts require explicit operator selection of personal voice under `pr-writing`.

Use this when:

- you want Ivan's voice available for prose published, submitted, or sent as Ivan
- you are comfortable with a more opinionated `AGENTS.md`
- you want a ready-made profile instead of writing a personal one from scratch

The `ivan-writing` skill is installed automatically by `scripts/install-profile.sh` when this profile is selected. It provides register-specific guidance (technical/operator, professional/application, casual/informal) and voice/cadence/word-choice rules. It is not the default for internal worker reports.

### `shared-context-improved.md`

Purpose: The shared profile plus strong routing rules for the optional context-improved toolchain.

Use this when:

- you have enabled `profiles/optional/opencode.context-improved.json`
- you have applied `./scripts/enable-optional.sh context-improved` or installed this AGENTS profile with `./scripts/install-profile.sh --apply`
- local `ast_grep` and enabled `context7` are actually available in the running environment
- `cymbal` is available on `PATH` when you want agents to start unfamiliar-code navigation there; the context-improved install attempts to wire its OpenCode hook when present, without making hook success a bundle requirement
- you want agents to prefer the richer context and navigation workflow explicitly

### `personal-context-improved.md`

Purpose: The personal-default profile plus strong routing rules for the optional context-improved toolchain. Writing guidance is identical to personal-default.

Use this when:

- you want the same Ivan-voice selection as personal-default: published, submitted, or sent as Ivan, with internal reports remaining neutral unless requested
- you have enabled `profiles/optional/opencode.context-improved.json`
- you have applied `./scripts/enable-optional.sh context-improved` or installed this AGENTS profile with `./scripts/install-profile.sh --apply`
- you want the AGENTS policy to assume the context-improved tool bundle is present
- `cymbal` is available on `PATH` when you want agents to start unfamiliar-code navigation there; the context-improved install attempts to wire its OpenCode hook when present, without making hook success a bundle requirement

## Install selection

The installer uses `shared` by default.

By default, the installer replaces the selected `AGENTS.md` after backing it up. When the operator needs to keep an existing file and reconcile the new routing rules afterward, the merge flow should use `OPENCODE_AGENTS_MODE=skip` so the user's file stays in place.

Install the shared profile:

```bash
./scripts/install-profile.sh --apply
```

Install the sanitized personal-default profile:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh --apply
```

Install the shared context-improved profile after writing the Context7 key to `secrets/context7` in the target config directory (see the README's MCP API keys section):

```bash
./scripts/write-secret.sh context7
OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh --apply
```

Install the personal context-improved profile the same way:

```bash
OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh --apply
```

Some notes:

- the `*-context-improved` AGENTS profiles auto-apply `context-improved` during `./scripts/install-profile.sh --apply`; use `./scripts/enable-optional.sh context-improved` when you want to add the bundle after a plain install
- the `*-context-improved` install commands require `jq`, `uvx`, and a non-blank `secrets/context7` file under the selected `OPENCODE_CONFIG_DIR` because the installer preflights and auto-applies the matching bundle; `cymbal` remains optional
- `cymbal hook install opencode --scope user` also runs during a plain `./scripts/install-profile.sh --apply` when `cymbal` is already on `PATH`
- the plain `shared` and `personal-default` profiles are the capability-safe defaults for the base install
- `skip` is the preservation path for an existing `AGENTS.md`; it leaves the file untouched so the agent can fold in the new guidance structurally afterward

The installer backs up any existing target config files before replacing them.
