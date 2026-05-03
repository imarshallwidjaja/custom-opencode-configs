# For LLM Agents

This document tells an Opencode agent how to set up this repository for a less technical operator.

Use it when the operator says things like:

- "Set this repo up as my Opencode config."
- "Install this custom Opencode profile for me."
- "Read this repo and walk me through the setup."

## Operator Prompt

Give the agent this repository and this document, then say:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, preserve my existing AGENTS.md as the base document for any merge unless I explicitly approve full replacement, run the setup commands for me, and verify the final Opencode config.
```

## What This Repo Actually Supports

Do not invent extra setup questions. This repository exposes the following real choices:

1. Which installable `AGENTS.md` profile to use:
   - `shared`
   - `personal-default`
   - `shared-context-improved`
   - `personal-context-improved`
2. Which Opencode config directory to install into:
   - default `~/.config/opencode`
   - a custom `OPENCODE_CONFIG_DIR`
3. Whether to enable the optional context-improved bundle:
   - none
   - `context-improved`
4. Whether to enable the optional `context7`-only MCP snippet when the full context-improved bundle is not being used:
   - none
   - `mcp-context7-enabled`
5. Whether to enable one optional LSP snippet:
    - none
    - `lsp-markdown-typescript`
    - `lsp-python`
    - `lsp-all-recommended`
6. Whether to install the optional VS Code `tctinh.vscode-hive` extension.

Some setup facts are not user choices:

- The default full install path is `./scripts/install-profile.sh`.
- The repo uses remote GitHub Copilot models in `opencode.json` and `agent_hive.json`.
- The published `opencode-hive@latest` plugin is installed by Opencode on first run.
- The optional context-improved bundle adds `context-mode@latest`, local `ast_grep`, enabled `context7`, and a matching `agent_hive.json` overlay that disables `ast_grep` for Hive workers.
- `context7` is present in the base config but disabled by default.
- `cymbal` is not configured through `opencode.json`. It is a separate CLI tool that the context-improved AGENTS profiles know how to use when it is installed and available on `PATH`.
- No LSP snippet is enabled by default.
- Direct `apm install -g ...` is not the right default for first-time setup because it does not install `opencode.json`, `agent_hive.json`, or `AGENTS.md`.
- When merging into an existing `AGENTS.md`, start from the user's file and reconcile the selected profile into it instead of replacing it by default.
- AGENTS profile selection changes operating rules, not just tool routing. Preserve the selected profile's parity-validation wording, failed-subagent retry policy, subagent final-response instructions, and resume-work guidance when merging.
- The installable profiles can mention `resume-tailoring` as guidance for resume, CV, and cover-letter work. Treat that as profile policy only. It does not mean this repository bundles that skill.

To make it simple: use the repo scripts for the normal setup path, then offer the optional bundles only after the base profile is installed.

## Files To Read First

Before making changes, read these files from this repository:

- `README.md`
- `profiles/agents/README.md`
- `profiles/optional/README.md`
- `scripts/install-profile.sh`
- `scripts/enable-optional.sh`

## Interview Rules

- Ask one setup question at a time.
- Explain each option in plain language.
- Recommend the safest default when the operator is unsure.
- Read the user's existing `AGENTS.md` before proposing any merge edits.
- Compare the user's `AGENTS.md` against the selected profile before writing anything.
- Add missing prescribed guidance into the user's structure instead of overwriting it by default.
- Identify real conflicts before editing them.
- Ask permission before consolidating, rewriting, or deleting conflicting instructions.
- Do not push optional tooling unless the operator wants it and the machine can support it.
- Use the repository scripts instead of manually copying files.
- If a prerequisite is missing, ask whether the operator wants you to install it or skip the related optional feature.
- If the operator wants the context-improved workflow, explain that the matching `shared-context-improved` or `personal-context-improved` profile now applies the `context-improved` JSON overlays automatically during install.
- Make it clear that `cymbal` is an optional CLI dependency, not a bundled config entry. If it is missing, the context-improved profile can still work, but agents will fall back to the other available search tools.
- When the operator wants `cymbal`, install it with Homebrew using `brew install 1broseidon/tap/cymbal` if Homebrew is available on the machine.
- Keep the operator informed about what you are about to run.
- Treat AGENTS profile choice as an operating-policy choice too, not only a toolchain choice.
- During AGENTS merges, preserve the selected profile's parity-validation wording, new-session retry rule for failed subagents, explicit subagent final-response instructions, and resume-work guidance.

## Recommended Defaults

Use these defaults unless the operator asks for something else:

- Install into `~/.config/opencode`.
- Use the `shared` AGENTS profile.
- Skip optional MCP and LSP snippets unless there is a clear need.
- Install the VS Code Hive extension only if the operator uses VS Code.

When the operator explicitly wants the richer local search and context workflow, recommend this pair together:

- `shared-context-improved` as the AGENTS profile
- `context-improved` as the optional JSON overlay

## Interview And Setup Workflow

Follow this order.

### 1. Confirm the target location

Ask:

```text
Do you want this installed into the normal Opencode config directory at ~/.config/opencode, or do you want a custom config directory?
```

Recommendation:

- Recommend `~/.config/opencode` unless the operator already uses a custom config layout.

If they choose a custom location, use `OPENCODE_CONFIG_DIR=/path/to/dir` for both install scripts.

### 2. Check the required base prerequisites

Verify or install the local tools:

- `git`
- `curl`
- `opencode`

Also verify that the operator has GitHub Copilot access available on their GitHub account before running `opencode auth login -p github-copilot`.

If `opencode` is missing, the standard install command is:

```bash
curl -fsSL https://opencode.ai/install | bash
```

If the operator wants the richer local navigation workflow and `cymbal` is missing, install it with:

```bash
brew install 1broseidon/tap/cymbal
```

Only do that when Homebrew is available. If `brew` is missing, explain that `cymbal` stays optional and continue with the base install unless the operator asks you to stop and install Homebrew first.

If the repository is not already cloned, clone it before continuing.

### 3. Authenticate Opencode

Ask:

```text
Have you already signed Opencode into GitHub Copilot on this machine, or should I do that now?
```

If needed, run:

```bash
opencode auth login -p github-copilot
```

### 4. Choose the AGENTS profile

Ask:

```text
Do you want the neutral shared profile, the personal-default profile with the author's writing style, or one of the context-improved variants that assume the richer optional local toolchain is enabled too?
```

Explain the options like this:

- `shared`: the safest team-friendly default
- `personal-default`: the shared rules plus the author's writing voice and phrase patterns
- `shared-context-improved`: the shared profile plus strong routing rules for `context-mode`, `ast-grep`, `context7`, and optional `cymbal`
- `personal-context-improved`: the personal-default profile plus the same context-improved routing rules

Recommendation:

- Recommend `shared` unless the operator explicitly wants the author's style.
- Recommend `shared-context-improved` only when the operator wants that richer workflow and is willing to satisfy the extra dependencies.

### 5. Install the base profile

Explain this before running the installer: it replaces the target directory's `opencode.json`, `agent_hive.json`, `AGENTS.md`, `skills/`, `agents/`, and `commands/` contents with this repo's versions, and it writes timestamped backups under `<target>/.backup/` first when those paths already exist. For the `shared-context-improved` and `personal-context-improved` profiles, it also preflights `jq`, `context-mode`, `uvx`, and `CONTEXT7_API_KEY`, then auto-applies the matching `context-improved` overlays. This is the clean install path; when you are merging into an existing `AGENTS.md`, use the manual merge workflow below so the user's file stays the base.

Run one of these:

```bash
./scripts/install-profile.sh
```

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
```

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh
```

If a custom config directory was chosen, include `OPENCODE_CONFIG_DIR=/path/to/dir` as well.

Do not use the APM-only install path for first-time setup unless the operator explicitly asks for it.

### Merge an existing `AGENTS.md` with the selected profile

When the target already has an `AGENTS.md`, follow this order:

1. Run `OPENCODE_AGENTS_MODE=skip ./scripts/install-profile.sh` so the installer does not replace the user's file.
2. Read the user's current `AGENTS.md` and the selected profile from this repository.
3. Map the sections and instruction intent in both documents.
4. Add compatible missing guidance into the user's structure without overwriting user content by default. That includes the profile's parity-validation wording, failed-subagent retry policy, subagent final-response instructions, and `resume-tailoring` guidance when the selected profile includes it.
5. Stop when you find a real conflict and present it to the user.
6. Only consolidate, rewrite, or delete conflicting instructions after explicit approval.
7. Back up the user's `AGENTS.md` before writing the merged result.

### 6. Offer the optional context-improved bundle first

Ask:

```text
Do you want the richer local context and code-navigation workflow on this machine? That enables context-mode, local ast-grep, and context7 together, adds the matching Agent Hive overlay, and pairs best with the shared-context-improved or personal-context-improved AGENTS profile.
```

Only enable it if:

- the operator wants it
- `jq` is installed
- `context-mode` is on `PATH`
- `uvx` is on `PATH`
- `CONTEXT7_API_KEY` is set
- the machine can reach `https://mcp.context7.com/mcp`

Optional but recommended for the full navigation workflow:

- `cymbal` on `PATH`

If `cymbal` is missing and `brew` is available, install it with:

```bash
brew install 1broseidon/tap/cymbal
```

Explain this clearly:

- `cymbal` is a CLI tool the AGENTS profile can call when it is installed
- it is not configured in `opencode.json`
- if it is missing, the context-improved profile still works, but agents will fall back to the other available search tools

If the operator wants the context-improved bundle and the selected AGENTS profile is one of the context-improved variants, let `scripts/install-profile.sh` handle it automatically.

If the operator wants the context-improved bundle but the selected AGENTS profile is not one of the context-improved variants, offer to switch the AGENTS profile first.

If all conditions are met and the selected AGENTS profile is not one of the context-improved variants, run:

```bash
./scripts/enable-optional.sh context-improved
```

### 7. Offer the optional `context7` MCP when the full bundle is not being used

Ask:

```text
Do you want me to enable the optional context7 documentation MCP? It needs a CONTEXT7_API_KEY environment variable.
```

Only enable it if:

- the operator wants it
- the context-improved bundle was not already enabled
- `jq` is installed
- `CONTEXT7_API_KEY` is set
- the machine can reach `https://mcp.context7.com/mcp`

If all conditions are met, run:

```bash
./scripts/enable-optional.sh mcp-context7-enabled
```

Some notes:

- `scripts/enable-optional.sh` requires `jq`.
- `agent_hive.json` still disables `context7` for Hive workers by default. That is part of this profile.
- the `context-improved` bundle additionally disables `ast_grep` for Hive workers through its `agent_hive.json` overlay.
- when `shared-context-improved` or `personal-context-improved` is selected, `scripts/install-profile.sh` applies that bundle automatically instead of requiring this separate step.

### 8. Offer the optional LSP bundles

Ask this first:

```text
Do you want optional local language servers enabled for this machine, or would you prefer to keep the setup minimal for now?
```

If they want LSPs, ask:

```text
Which best matches your work on this machine: Markdown and TypeScript, Python, all of them, or none?
```

Map their answer to the bundle:

- Markdown and TypeScript: `lsp-markdown-typescript`
- Python: `lsp-python`
- Both or full recommended stack: `lsp-all-recommended`

Before applying a bundle:

- check that `jq` is installed
- check that the required binaries are on `PATH`

Bundle prerequisites:

- `lsp-markdown-typescript`: `marksman`, `vtsls`
- `lsp-python`: `ruff`, `ty`
- `lsp-all-recommended`: `marksman`, `vtsls`, `ruff`, `ty`

Recommended install guidance when binaries are missing:

- `vtsls`: install Node.js LTS, then run `npm install -g @vtsls/language-server`
- `ruff`: install `uv`, then run `uv tool install ruff@latest`
- `ty`: install `uv`, then run `uv tool install ty@latest`
- `marksman`: install it using the official instructions at `https://github.com/artempyanykh/marksman/blob/main/docs/install.md`

Apply the chosen bundle with:

```bash
./scripts/enable-optional.sh <snippet-name>
```

Do not apply an LSP snippet before the base profile exists in the target directory.

### 9. Offer the optional VS Code extension

Ask:

```text
Do you use VS Code on this machine, and if so, do you want the optional Agent Hive extension installed there too?
```

If yes and the `code` CLI is available, run:

```bash
code --install-extension tctinh.vscode-hive
```

If the `code` CLI is not available, tell the operator to install `Agent Hive` from the VS Code marketplace manually.

### 10. Start Opencode once

Run:

```bash
opencode
```

This allows Opencode to resolve `opencode-hive@latest` from `opencode.json` on first run.

If the context-improved bundle was enabled, this first run also needs to succeed without command-not-found errors for `context-mode` or the local MCP tooling.

Success signal:

- Opencode starts without reporting plugin-resolution or command-not-found errors for the base profile.

### 11. Verify the final state

Verify that the target config directory now contains:

- `opencode.json`
- `agent_hive.json`
- `AGENTS.md`
- `skills/`
- `agents/`
- `commands/`

If optional snippets were enabled, verify that the relevant entries exist in `opencode.json`.

Concrete checks:

- if `context-improved` was enabled, verify `plugin` includes `context-mode@latest`
- if `context-improved` was enabled, verify `mcp.context-mode`, `mcp.ast_grep`, and `mcp.context7.enabled` exist in `opencode.json`
- if `context7` was enabled, verify `mcp.context7.enabled` is `true`
- if an LSP bundle was enabled, verify the expected `lsp.<name>.command` entries exist for the selected servers
- if `lsp-markdown-typescript` was enabled, verify `lsp.typescript.disabled` is `true`
- if `lsp-python` or `lsp-all-recommended` was enabled, verify `lsp.pyright.disabled` and `lsp.basedpyright.disabled` are `true`

If the operator wanted `cymbal`, verify that `cymbal` is available on `PATH` with a simple command such as:

```bash
which cymbal
```

If `brew` was used to install it, prefer confirming the installed formula too:

```bash
brew list --versions cymbal
```

Then report back with:

- the install directory used
- the AGENTS profile selected
- whether the context-improved bundle was enabled
- whether `context7` was enabled
- which LSP bundle, if any, was enabled
- whether `cymbal` is installed as a CLI on this machine
- whether the VS Code extension was installed
- any skipped options and why

## Decision Inventory From The Repo Audit

Use this as the source of truth for the interview.

| Decision | Choices | Default | Requirements |
|---|---|---|---|
| AGENTS merge strategy | preserve the user's `AGENTS.md` as the base, or replace it only with explicit approval | preserve the user's file | explicit approval required before full replacement or conflict consolidation |
| AGENTS profile | `shared`, `personal-default`, `shared-context-improved`, `personal-context-improved` | `shared` | none |
| Config directory | `~/.config/opencode` or custom path | `~/.config/opencode` | none |
| Context-improved bundle | enable or skip | skip | `jq`, `context-mode`, `uvx`, `CONTEXT7_API_KEY`, network access; `cymbal` optional CLI |
| `context7` MCP only | enable or skip | skip | `jq`, `CONTEXT7_API_KEY`, network access |
| LSP bundle | none, `lsp-markdown-typescript`, `lsp-python`, `lsp-all-recommended` | none | `jq` plus required binaries |
| VS Code Hive extension | install or skip | skip unless operator uses VS Code | VS Code and usually `code` CLI |

## Commands The Agent Will Usually Need

Base install:

```bash
./scripts/install-profile.sh
```

Base install with the personal profile:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

Base install with the shared context-improved profile:

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
```

Base install with the personal context-improved profile:

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh
```

Base install into a custom config directory:

```bash
OPENCODE_CONFIG_DIR=/path/to/opencode-config ./scripts/install-profile.sh
```

Enable the context-improved bundle:

```bash
./scripts/enable-optional.sh context-improved
```

Use that command when the install already used `shared` or `personal-default` and you want to add the richer bundle afterward.

Enable `context7` only:

```bash
./scripts/enable-optional.sh mcp-context7-enabled
```

Enable Markdown and TypeScript LSPs:

```bash
./scripts/enable-optional.sh lsp-markdown-typescript
```

Enable Python LSPs:

```bash
./scripts/enable-optional.sh lsp-python
```

Enable all recommended LSPs:

```bash
./scripts/enable-optional.sh lsp-all-recommended
```

Install the VS Code Hive extension:

```bash
code --install-extension tctinh.vscode-hive
```

## What Not To Do

- Do not ask the operator to choose model IDs from this repo. Those defaults are already encoded.
- Do not default to direct `apm install -g` for first-time setup.
- Do not treat AGENTS merge as a blind append.
- Do not silently overwrite the user's existing `AGENTS.md` during merge.
- Do not silently clean up conflicts by deleting or rewriting instructions.
- Do not enable optional snippets without first checking their prerequisites.
- Do not enable the context-improved bundle without also checking whether the chosen `AGENTS.md` profile matches that capability set.
- Do not enable LSP snippets before `./scripts/install-profile.sh` has created the target `opencode.json`.
- Do not assume `personal-default` is appropriate for every operator.
- Do not describe `cymbal` as a bundled MCP or JSON config entry. It is a separate CLI dependency.
- Do not overwhelm the operator with all questions at once.
